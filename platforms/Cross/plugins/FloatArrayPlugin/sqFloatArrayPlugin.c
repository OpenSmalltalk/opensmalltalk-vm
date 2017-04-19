void quicksort(float* array, int from, int to) {
    if (from < to) {
        int p = partition(array, from, to);
        quicksort(array, from, p);
        quicksort(array, p + 1, to);
    }
    return;
}

int partition(float* array, int from, int to) {
    float pivot = array[from];
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
