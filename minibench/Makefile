
all: minibench

%: %.cu
	nvcc $^ -o $@

test: minibench
	./minibench trace

clean:
	rm -f minibench
