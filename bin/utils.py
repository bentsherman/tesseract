import copy
import dill as pickle
import h5py
import io
import numpy as np
import sklearn.base
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