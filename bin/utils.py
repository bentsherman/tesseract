import copy
import dill as pickle
import forestci
import h5py
import io
import numpy as np
import sklearn.base
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import FunctionTransformer
import tensorflow as tf



class CategoryTreeRegressor(sklearn.base.BaseEstimator):
    '''
    Regression tree that trains a regressor for each value of
    a categorical variable in a dataset. The categorical variable
    is assumed to be one-hot encoded in the dataset.
    '''

    def __init__(self, columns, reg):
        self.columns = columns
        self.reg = reg

    def fit(self, X, y):
        # initialize dictionary of regressors
        self.regs_ = {}

        # determine unique categories
        c_values = np.unique(X[:, self.columns], axis=0)

        # train regressor for each category
        for c in c_values:
            # initialize regressor
            reg = sklearn.base.clone(self.reg)

            # extract dataset
            idx = (X[:, self.columns] == c).all(axis=1)
            X_c = X[idx]
            y_c = y[idx]

            # train regressor
            reg.fit(X_c, y_c)

            # save regressor
            self.regs_[tuple(c)] = reg

        return self

    def predict(self, X):
        # initialize predictions array
        y = np.empty(X.shape[0])

        # determine unique categories
        c_values = np.unique(X[:, self.columns], axis=0)

        # compute predictions for each category
        for c in c_values:
            # raise error if there is no regressor for this category
            if tuple(c) not in self.regs_:
                raise ValueError('category %s was not present in the training set' % (c))

            # compute predictions
            reg = self.regs_[tuple(c)]
            idx = (X[:, self.columns] == c).all(axis=1)

            y[idx] = reg.predict(X[idx])

        return y



class KerasRegressor(tf.keras.wrappers.scikit_learn.KerasRegressor):
    '''
    TensorFlow Keras API neural network regressor.

    Workaround the tf.keras.wrappers.scikit_learn.KerasRegressor serialization
    issue using BytesIO and HDF5 in order to enable pickle dumps.

    Adapted from: https://github.com/keras-team/keras/issues/4274#issuecomment-519226139
    '''

    def __getstate__(self):
        state = self.__dict__
        if 'model' in state:
            model = state['model']
            model_hdf5_bio = io.BytesIO()
            with h5py.File(model_hdf5_bio, mode='w') as file:
                model.save(file)
            state['model'] = model_hdf5_bio
            state_copy = copy.deepcopy(state)
            state['model'] = model
            return state_copy
        else:
            return state

    def __setstate__(self, state):
        if 'model' in state:
            model_hdf5_bio = state['model']
            with h5py.File(model_hdf5_bio, mode='r') as file:
                state['model'] = tf.keras.models.load_model(file)
        self.__dict__ = state



class RegressorWithOutputTransform(sklearn.base.BaseEstimator):

    def __init__(self, model, transform=None):
        self.model = model

        if transform == 'sqrt':
            np_pow2 = lambda x: np.power(x, 2)
            self.transform = FunctionTransformer(func=np_pow2, inverse_func=np.sqrt)
        elif transform == 'log':
            self.transform = FunctionTransformer(func=np.exp, inverse_func=np.log)
        else:
            self.transform = FunctionTransformer()

    def fit(self, X, y):
        # train regressor on transformed target data
        self.model.fit(X, self.transform.inverse_transform(y))

        return self

    def predict(self, X):
        # compute predictions from base model
        y = self.model.predict(X)

        # return transformed predictions
        return self.transform.transform(y)



class KerasRegressorWithIntervals(KerasRegressor):

    def inverse_tau(self, N, lmbda=1e-5, p_dropout=0.1, ls_2=0.005):
        return (2 * N * lmbda) / (1 - p_dropout) / ls_2

    def fit(self, X, y):
        # fit neural network
        super(KerasRegressorWithIntervals, self).fit(X, y)

        # save training set size for tau adjustment
        self.n_train_samples = X.shape[0]

        return self

    def predict(self, X, n_preds=10, alpha=0.05):
        # compute several predictions for each sample
        y_preds = np.array([super(KerasRegressorWithIntervals, self).predict(X) for _ in range(n_preds)])

        # compute point predictions and prediction intervals
        y_pred = np.mean(y_preds, axis=0)
        y_lower = np.percentile(y_preds,       100 * alpha / 2, axis=0)
        y_upper = np.percentile(y_preds, 100 - 100 * alpha / 2, axis=0)

        # compute tau adjustment
        tau_inv = self.inverse_tau(self.n_train_samples)
        y_lower -= 2.0 * tau_inv
        y_upper += 2.0 * tau_inv

        return y_pred, y_lower, y_upper



class RandomForestRegressorWithIntervals(RandomForestRegressor):

    def fit(self, X, y):
        # fit random forest
        super(RandomForestRegressorWithIntervals, self).fit(X, y)

        # save training set for variance estimate
        self.X_train = X

        return self

    def predict(self, X, n_stds=2.0):
        # compute predictions
        y_pred = super(RandomForestRegressorWithIntervals, self).predict(X)

        # compute variance estimate
        V_IJ_U = forestci.random_forest_error(self, self.X_train, X)

        # compute prediction intervals
        y_err = n_stds * np.sqrt(V_IJ_U)
        y_lower = y_pred - y_err
        y_upper = y_pred + y_err

        return y_pred, y_lower, y_upper