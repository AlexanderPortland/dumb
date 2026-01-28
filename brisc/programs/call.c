int bar(int x, int y) { return x + y; }

// Returns 2x + 12
int foo(int x) { 
    return x + bar(x, 12);
}

int main() {
    int x = 10;

    x = foo(x);

    // Should return 0d32, or 0x20
    return x;
}