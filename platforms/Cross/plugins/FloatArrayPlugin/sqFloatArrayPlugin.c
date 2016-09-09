#include <FloatArrayPlugin.h>

void quicksort(float* array, int from, int to) {
    int stack[to - from + 1];
    int top = -1;
    
    top++;
    stack[top] = from;
    top++;
    stack[top] = to;
    
    while (top >= 0) {
        int high;
        int low;
        
        high = stack[top];
        top--;
        low = stack[top];
        top--;
        
        int pivotPosition = partition(array, low, high);
        
        if (pivotPosition - 1 > low) {
            if (pivotPosition - 1 - low > 10) {
                top++;
                stack[top] = low;
                top++;
                stack[top] = pivotPosition - 1;
            } else {
                insort(array, low, pivotPosition - 1);
            }
        }
        
        if (pivotPosition + 1 < high) {
            if (high - (pivotPosition + 1) > 10) {
                top++;
                stack[top] = pivotPosition + 1;
                top++;
                stack[top] = high;
            } else {
                insort(array, pivotPosition + 1, high);
            }
        }
        
    }
    
    if (from < to) {
        int p = partition(array, from, to);
        quicksort(array, from, p);
        quicksort(array, p + 1, to);
    }
    
    return;
}

int partition(float* array, int from, int to) {
    float possiblePivots[] = { array[from], array[(to - from) / 2 + from], array[to] };
    float pivot;
    pivot = possiblePivots[0] < possiblePivots[2] ? possiblePivots[0] : possiblePivots[2];
    pivot = pivot > possiblePivots[1] ? pivot : possiblePivots[1];
    
    int i = from - 1;
    int j = to + 1;
    while (-1) {
        do {
            i += 1;
        } while (array[i] < pivot);
        do {
            j -= 1;
        } while (array[j] > pivot);
        if (i >= j) {
            return j;
        }
        float a = array[i];
        float b = array[j];
        array[i] = b;
        array[j] = a;
    }
}

void insort(float* array, int from, int to) {
    int i;
    for (i = from; i <= to; i++) {
        int j = i;
        while (j > 0 && array[j - 1] > array[j]) {
            float a = array[j - 1];
            float b = array[j];
            array[j] = b;
            array[j - 1] = a;
            j--;
        }
    }
}
