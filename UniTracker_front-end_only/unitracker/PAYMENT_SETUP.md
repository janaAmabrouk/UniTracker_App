# Payment Methods Setup Guide

This guide explains how to set up the payment methods functionality in UniTracker.

## Database Tables Required

### 1. user_payment_cards Table

```sql
-- Create the user_payment_cards table
CREATE TABLE user_payment_cards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  card_number_encrypted TEXT NOT NULL,
  card_holder_name TEXT NOT NULL,
  expiry_month TEXT NOT NULL,
  expiry_year TEXT NOT NULL,
  card_type TEXT NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_user_payment_cards_user_id ON user_payment_cards(user_id);
CREATE INDEX idx_user_payment_cards_is_default ON user_payment_cards(is_default);

-- Enable Row Level Security (RLS)
ALTER TABLE user_payment_cards ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own payment cards" ON user_payment_cards
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payment cards" ON user_payment_cards
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment cards" ON user_payment_cards
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own payment cards" ON user_payment_cards
  FOR DELETE USING (auth.uid() = user_id);
```

### 2. payment_history Table

```sql
-- Create the payment_history table
CREATE TABLE payment_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  card_id UUID REFERENCES user_payment_cards(id) ON DELETE SET NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EGP',
  status TEXT NOT NULL DEFAULT 'pending',
  description TEXT NOT NULL,
  reservation_id UUID REFERENCES reservations(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_payment_history_user_id ON payment_history(user_id);
CREATE INDEX idx_payment_history_status ON payment_history(status);
CREATE INDEX idx_payment_history_created_at ON payment_history(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE payment_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own payment history" ON payment_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payment records" ON payment_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment records" ON payment_history
  FOR UPDATE USING (auth.uid() = user_id);
```

## Features Implemented

### 1. Payment Methods Management
- ✅ Add new payment cards
- ✅ View saved payment cards
- ✅ Remove payment cards
- ✅ Set default payment method
- ✅ Card type detection (Visa, Mastercard, American Express, Discover)
- ✅ Real-time card validation using Luhn algorithm
- ✅ Expiry date validation
- ✅ Card number formatting

### 2. Payment History
- ✅ View payment transaction history
- ✅ Total spent calculation
- ✅ Payment status tracking (completed, pending, failed, cancelled)
- ✅ Transaction details with timestamps
- ✅ Payment history filtering

### 3. Security Features
- ✅ Card number encryption (basic implementation)
- ✅ Row Level Security (RLS) policies
- ✅ User-specific data access
- ✅ Input validation and sanitization

### 4. User Experience
- ✅ Modern UI with card type indicators
- ✅ Real-time card type detection
- ✅ Default card highlighting
- ✅ Loading states and error handling
- ✅ Responsive design
- ✅ Intuitive navigation

## Usage

1. **Adding a Payment Card:**
   - Navigate to Profile → Payment Methods
   - Tap "Add New Card"
   - Fill in card details (number, expiry, CVV, name)
   - Card type is automatically detected
   - Validation ensures data integrity

2. **Managing Payment Cards:**
   - View all saved cards in Payment Methods
   - Set a card as default using the star icon
   - Remove cards using the delete icon
   - Default cards are highlighted with a blue badge

3. **Viewing Payment History:**
   - Navigate to Profile → Payment History
   - View total amount spent
   - Browse recent transactions
   - See payment status and timestamps

## Security Notes

⚠️ **Important:** This implementation includes basic security measures, but for production use, consider:

1. **Enhanced Encryption:** Use proper encryption libraries for card data
2. **PCI Compliance:** Ensure compliance with Payment Card Industry standards
3. **Tokenization:** Use payment tokens instead of storing actual card numbers
4. **Audit Logging:** Implement comprehensive audit trails
5. **Rate Limiting:** Add rate limiting for payment operations
6. **3D Secure:** Implement 3D Secure authentication

## Testing

To test the payment functionality:

1. Use test card numbers:
   - Visa: 4242 4242 4242 4242
   - Mastercard: 5555 5555 5555 4444
   - American Express: 3782 822463 10005

2. Use future expiry dates (e.g., 12/25)

3. Use any 3-digit CVV

4. Use any valid name format (first and last name)

## Future Enhancements

- [ ] Integration with real payment gateways (Stripe, PayPal)
- [ ] Subscription management
- [ ] Payment analytics and reporting
- [ ] Multi-currency support
- [ ] Payment method preferences
- [ ] Automated payment processing
- [ ] Payment notifications
- [ ] Refund processing 