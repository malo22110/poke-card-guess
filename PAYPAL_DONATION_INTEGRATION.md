# PayPal Donation Integration Plan

## Overview

This document outlines the implementation plan for integrating PayPal donations with trophy tracking in PokeCardGuess.

## Current Status

- ✅ Donation screen created (`/lib/screens/donation_screen.dart`)
- ✅ Backend donation endpoint exists (`/users/donation`)
- ✅ Donation trophies defined in database
- ⏳ PayPal SDK integration pending
- ⏳ Route registration needed

## Donation Trophies

1. **Supporter** (Bronze) - First donation
2. **Generous** (Silver) - $5 or more
3. **Patron** (Gold) - $20 or more
4. **Benefactor** (Diamond) - $50 or more

## Implementation Steps

### 1. Register Donation Route

Add to `main.dart`:

```dart
'/donate': (context) => const DonationScreen(),
```

### 2. Update Footer (footer.dart line 84)

Replace:

```dart
launchUrl(Uri.parse('https://www.paypal.com/donate/?hosted_button_id=3W3L9NC2BVGSS'));
```

With:

```dart
Navigator.of(context).pushNamed('/donate');
```

### 3. PayPal SDK Integration

#### Get PayPal Client ID

1. Go to https://developer.paypal.com/
2. Create an app in the Dashboard
3. Get your Client ID (use Sandbox for testing, Live for production)

#### Update donation_screen.dart

Replace `YOUR_CLIENT_ID` on line 39 with your actual PayPal Client ID:

```dart
..src = 'https://www.paypal.com/sdk/js?client-id=YOUR_ACTUAL_CLIENT_ID&currency=USD'
```

#### Implement PayPal Button

In the donate button's onPressed (around line 377), replace the dialog with:

```dart
// Create PayPal button container
final paypalContainer = html.document.getElementById('paypal-button-container');
if (paypalContainer == null) {
  final container = html.DivElement()
    ..id = 'paypal-button-container'
    ..style.width = '100%';
  // Add to DOM and render PayPal button
}

// Use js package to call PayPal SDK
js.context.callMethod('paypal').callMethod('Buttons', [
  js.JsObject.jsify({
    'createOrder': (data, actions) {
      return actions.order.create({
        'purchase_units': [{
          'amount': {
            'value': amount.toStringAsFixed(2)
          }
        }]
      });
    },
    'onApprove': (data, actions) async {
      await actions.order.capture();
      // Call _processDonation to record on backend
      await _processDonation(amount);
    }
  })
]).callMethod('render', ['#paypal-button-container']);
```

### 4. Add to pubspec.yaml

```yaml
dependencies:
  js: ^0.6.7 # For PayPal SDK integration
```

### 5. Backend Trophy Check

The backend already has the logic to check donation trophies. When `/users/donation` is called, it should:

1. Increment `totalDonated` by the amount
2. Check and award donation trophies automatically
3. Return unlocked trophies in the response

Update `users.controller.ts` to check trophies after donation:

```typescript
@Post('donation')
async recordDonation(@Request() req, @Body() body: { amount: number }) {
  const userId = req.user.userId;
  const amountInCents = Math.round(body.amount * 100);
  const user = await this.usersService.addDonation(userId, amountInCents);

  // Check for donation trophies
  const newTrophies = await this.trophiesService.checkAndAwardTrophies(
    userId,
    { category: 'donation' },
  );

  return {
    success: true,
    totalDonated: user.totalDonated / 100,
    newTrophies,
  };
}
```

### 6. Add Donation Button to Game End Screen

In `game_screen.dart`, add a donation button to the final results screen (around line 650):

```dart
if (error == 'Game Finished!') {
  // ... existing code ...
  ElevatedButton.icon(
    onPressed: () => Navigator.of(context).pushNamed('/donate'),
    icon: const Icon(Icons.favorite),
    label: const Text('Support the Game'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF003087),
    ),
  ),
}
```

## Testing Checklist

- [ ] PayPal Sandbox account created
- [ ] Client ID configured
- [ ] Test $1 donation (should unlock Supporter)
- [ ] Test $5 donation (should unlock Generous)
- [ ] Test $20 donation (should unlock Patron)
- [ ] Test $50 donation (should unlock Benefactor)
- [ ] Trophy notifications appear
- [ ] Total donated updates correctly
- [ ] Donation screen accessible from footer
- [ ] Donation screen accessible from game end

## Security Notes

- Never expose your PayPal Secret Key in client code
- Use environment variables for Client ID
- Validate donations on the backend
- Implement webhook verification for production

## Resources

- PayPal SDK Docs: https://developer.paypal.com/sdk/donate/
- PayPal Developer Dashboard: https://developer.paypal.com/dashboard/
- Flutter Web + JS interop: https://dart.dev/web/js-interop
