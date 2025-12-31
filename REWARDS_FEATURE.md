# Rewards Feature - AI-Powered Card Recommendations

## Overview

The Rewards tab uses Perplexity AI to analyze your credit cards and recommend the best card to use for any purchase, maximizing your cashback or rewards points.

## How It Works

1. **Enter Store Name**: Type the name of the store where you're shopping (e.g., "Target", "Amazon", "Whole Foods")
2. **Get Recommendations**: The AI analyzes your cards and their benefits
3. **View Results**: See up to 3 ranked recommendations with:
   - Card name
   - Reason for recommendation
   - Estimated reward rate or cashback percentage

## Features

### Smart Analysis
- Considers category bonuses (e.g., 3% on dining, 5% on groceries)
- Evaluates merchant-specific rewards
- Compares cashback rates across all your cards
- Provides real-time, contextual recommendations

### Beautiful UI
- Gradient backgrounds and modern design
- Color-coded ranking system:
  - 🥇 Gold/Green for #1 recommendation
  - 🥈 Blue for #2 recommendation
  - 🥉 Orange for #3 recommendation
- Clear, easy-to-read reward estimates
- Responsive loading states

### Privacy-Focused
- API key stored locally on device
- No data sent to our servers
- Direct communication with Perplexity API only
- You control your API key

## Setup

### Getting Your Perplexity API Key

1. **Visit Perplexity**: Go to [perplexity.ai](https://www.perplexity.ai)
2. **Create Account**: Sign up for a free account
3. **Access API Settings**: Navigate to your account settings
4. **Generate Key**: Create a new API key
5. **Copy Key**: Save the key securely

### Adding API Key to App

1. Open the app and go to the **Rewards** tab
2. Tap the **key icon** (🔑) in the top right corner
3. Paste your API key in the text field
4. Tap **Save**

That's it! You're ready to get recommendations.

## Usage Examples

### Example 1: Grocery Shopping
**Input**: "Whole Foods"
**Output**:
- #1: Chase Sapphire Reserve - 3% on dining & travel, 1% on everything else
- #2: Amex Gold - 4x points on groceries (up to $25k/year)
- #3: Chase Freedom Flex - 5% rotating category (if groceries active)

### Example 2: Online Shopping
**Input**: "Amazon"
**Output**:
- #1: Amazon Prime Visa - 5% back on Amazon purchases
- #2: Chase Freedom Unlimited - 1.5% back on all purchases
- #3: Discover It - 5% rotating category (if Amazon active)

### Example 3: Gas Stations
**Input**: "Shell"
**Output**:
- #1: Costco Anywhere Visa - 4% back on gas
- #2: Chase Freedom Flex - 5% rotating category (if gas active)
- #3: Citi Double Cash - 2% back on all purchases

## Technical Details

### API Integration
- **Service**: Perplexity AI Chat Completions API
- **Model**: `llama-3.1-sonar-small-128k-online`
- **Temperature**: 0.2 (for consistent, factual responses)
- **Max Tokens**: 1000

### Data Flow
```
User Input → RewardsViewModel → PerplexityService → API
                ↓                                      ↓
            UI Update ← Parse Response ← JSON Response
```

### Error Handling
- No API key: Prompts user to add key
- Invalid store name: Asks for valid input
- No cards: Prompts to add cards first
- API errors: Shows user-friendly error messages
- Parse errors: Gracefully handles malformed responses

## Troubleshooting

### "No API key configured"
**Solution**: Tap the key icon and add your Perplexity API key

### "Please add some credit cards first"
**Solution**: Go to Settings tab and add your credit cards

### "API error with status code: 401"
**Solution**: Your API key is invalid. Check and re-enter it

### "API error with status code: 429"
**Solution**: You've exceeded your API rate limit. Wait a few minutes

### "No recommendations found"
**Solution**: Try a more specific or different store name

## Best Practices

1. **Be Specific**: Use full store names (e.g., "Target" not "store")
2. **Add Card Benefits**: Make sure your cards have benefits configured for better recommendations
3. **Keep Cards Updated**: Remove old cards you no longer use
4. **Check Multiple Stores**: Compare recommendations across similar stores
5. **Verify Recommendations**: Always double-check the AI's suggestions with your card's terms

## Limitations

- Requires active internet connection
- Depends on Perplexity API availability
- Recommendations are AI-generated and should be verified
- May not know about very new card benefits or promotions
- Limited to cards you've added to the app

## Future Enhancements

Potential improvements for future versions:
- Offline mode with cached recommendations
- Historical tracking of which cards you used where
- Spending analytics and optimization suggestions
- Integration with card issuer APIs for real-time benefit data
- Support for multiple currencies and international cards

## Support

For issues or questions:
- Check that your API key is valid
- Ensure you have an internet connection
- Verify your cards are properly configured
- Try restarting the app

---

**Note**: This feature is powered by AI and provides suggestions based on general card benefits. Always verify recommendations with your card's official terms and conditions.

