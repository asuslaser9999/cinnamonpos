/// Round cash totals up to the next thousand; leftover is donation.
class DonationRounding {
  DonationRounding._();

  static const unit = 1000.0;

  static double amount(double saleTotal) {
    if (saleTotal <= 0) return 0;
    final rounded = (saleTotal / unit).ceil() * unit;
    final donation = rounded - saleTotal;
    return donation < 0.0001 ? 0 : donation;
  }

  static double payable(double saleTotal) => saleTotal + amount(saleTotal);
}
