int fib(int x) {
    if (x < 1) return 0;
    if (x == 1) return 1;
    return fib(x - 1) + fib(x - 2);
}

int main() {
    // Should return 0d8, or 0x8
    return fib(6);
}