int main() {
    int x = 7;
    int y = 10;

    if (x > 5) {
        // This should be taken -> (7, 20)
        y += 10;
    }

    if (y <= 20) {
        if (x == 8) {
            y = 0;
        } else if (y != 21) {
            // This should be taken -> (5, 25)
            x -= 2;
            y += x;
        }
    }

    if (y >= 25 && x < 6) {
        // This should be taken -> (7, 127)
        y += 102;
    }

    // Should return 0d127, 0x7f
    return y;
}