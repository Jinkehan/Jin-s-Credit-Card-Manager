# Card Benefits JSON Editing Guide

This guide explains how to edit the `card-benefits.json` file to add, modify, or remove credit card definitions and their associated benefits.

## Table of Contents
1. [File Structure Overview](#file-structure-overview)
2. [Adding a New Card](#adding-a-new-card)
3. [Adding Benefits to a Card](#adding-benefits-to-a-card)
4. [Reminder Types](#reminder-types)
5. [Value Types](#value-types)
6. [Important Notes](#important-notes)
7. [Examples](#examples)

---

## File Structure Overview

The `card-benefits.json` file has the following top-level structure:

```json
{
  "schemaVersion": "1.0.1",
  "lastUpdated": "2025-12-31T00:00:00Z",
  "predefinedCards": [
    // Array of card objects
  ]
}
```

### Root Level Fields
- **schemaVersion** (string, required): Version of the schema. Increment when making breaking changes.
- **lastUpdated** (string, required): ISO 8601 timestamp (YYYY-MM-DDTHH:MM:SSZ) of last update.
- **predefinedCards** (array, required): Array of card definitions.

---

## Adding a New Card

Each card object has the following structure:

```json
{
  "id": "unique_card_id",
  "name": "Card Name",
  "issuer": "Bank Name",
  "cardNetwork": "Visa|Mastercard|Amex|Discover|Store|PayPal",
  "category": "premium_travel|cashback|rewards|travel|store|financing",
  "imageUrl": "https://raw.githubusercontent.com/.../Card_Pictures/image.jpg",
  "defaultBenefits": [
    // Array of benefit objects
  ]
}
```

### Card Fields
- **id** (string, required): Unique identifier (lowercase, underscores, no spaces). Example: `"chase_sapphire_reserve"`
- **name** (string, required): Full card name as it appears to users.
- **issuer** (string, required): Bank or financial institution name.
- **cardNetwork** (string, required): One of: `"Visa"`, `"Mastercard"`, `"Amex"`, `"Discover"`, `"Store"`, `"PayPal"`
- **category** (string, required): Card category. Common values:
  - `"premium_travel"` - Premium travel cards
  - `"cashback"` - Cashback cards
  - `"rewards"` - Points/miles cards
  - `"travel"` - Travel-focused cards
  - `"store"` - Store cards
  - `"financing"` - Financing/payment cards
- **imageUrl** (string, optional): Full URL to card image hosted on GitHub. Should point to `Card_Pictures/` directory.
- **defaultBenefits** (array, required): Array of benefit objects (can be empty `[]`).

---

## Adding Benefits to a Card

Each benefit object has the following structure:

```json
{
  "id": "unique_benefit_id",
  "name": "Benefit Name",
  "description": "Detailed description of the benefit",
  "category": "Travel|Dining|Shopping|Cashback|Transportation|Other",
  "value": {
    // Value object (see Value Types section)
  },
  "reminder": {
    // Reminder object (see Reminder Types section)
  },
  "usageTracking": {
    // Optional usage tracking object
  }
}
```

### Benefit Fields
- **id** (string, required): Unique identifier for this benefit (lowercase, underscores). Example: `"travel_credit_annual"`
- **name** (string, required): Short, descriptive name of the benefit.
- **description** (string, required): Detailed explanation of the benefit and any terms/conditions.
- **category** (string, required): Benefit category. Common values: `"Travel"`, `"Dining"`, `"Shopping"`, `"Cashback"`, `"Transportation"`, `"Other"`
- **value** (object, required): Value configuration (see [Value Types](#value-types))
- **reminder** (object, required): Reminder configuration (see [Reminder Types](#reminder-types))
- **usageTracking** (object, optional): Usage tracking configuration (see below)

### Usage Tracking Object
```json
{
  "enabled": true,
  "resetPeriod": "monthly|annual|semi_annual|quarterly"
}
```

- **enabled** (boolean, required): Whether usage tracking is enabled.
- **resetPeriod** (string, required): When the benefit resets. Must match the reminder type's frequency.

---

## Reminder Types

The reminder type determines when users are notified and when benefits expire. **Important**: Expiration dates are automatically set to the **last day of the corresponding period** (month/quarter/year), regardless of the reminder day.

### 1. Monthly Reminders

For benefits that reset every month (e.g., monthly credits):

```json
{
  "type": "monthly",
  "dayOfMonth": 1,
  "message": "Use your monthly credit this month!"
}
```

- **type**: `"monthly"`
- **dayOfMonth** (integer, required): Day of month when reminder is sent (1-31). Typically `1`.
- **message** (string, required): Reminder message.
- **Expiration**: Last day of each month (automatically calculated).

### 2. Annual Reminders

For benefits that reset annually based on card anniversary:

```json
{
  "type": "annual",
  "startDate": "card_anniversary",
  "daysBefore": 30,
  "message": "Don't forget to use your annual credit!"
}
```

- **type**: `"annual"`
- **startDate** (string, required): Must be `"card_anniversary"` (uses the card's anniversary date).
- **daysBefore** (integer, required): Days before anniversary to send reminder.
- **message** (string, required): Reminder message.
- **Expiration**: Last day of the anniversary month (automatically calculated).

### 3. Quarterly Reminders

For benefits that reset every quarter:

```json
{
  "type": "quarterly",
  "startMonth": 1,
  "dayOfMonth": 1,
  "message": "Check this quarter's bonus categories!"
}
```

- **type**: `"quarterly"`
- **startMonth** (integer, optional): Starting month (1-12). If omitted, uses card anniversary month.
- **dayOfMonth** (integer, optional): Day of month for reminder. Typically `1`.
- **message** (string, required): Reminder message.
- **Expiration**: Last day of each quarter month (automatically calculated).

### 4. Semi-Annual Reminders

For benefits that reset twice per year:

```json
{
  "type": "semi_annual",
  "periods": [
    {
      "startMonth": 1,
      "endMonth": 6
    },
    {
      "startMonth": 7,
      "endMonth": 12
    }
  ],
  "dayOfMonth": 1,
  "message": "Use your semi-annual credit!"
}
```

- **type**: `"semi_annual"`
- **periods** (array, required): Array of period objects with `startMonth` and `endMonth` (1-12).
- **dayOfMonth** (integer, optional): Day of month for reminder. Typically `1`.
- **message** (string, required): Reminder message.
- **Expiration**: Last day of the semi-annual period month (automatically calculated).

### 5. One-Time Reminders

For benefits that only occur once:

```json
{
  "type": "one_time",
  "date": "2025-01-15",
  "message": "Activate your membership!"
}
```

- **type**: `"one_time"`
- **date** (string, required): ISO 8601 date (YYYY-MM-DD).
- **message** (string, required): Reminder message.
- **Expiration**: Uses the specified date.

---

## Value Types

The value object describes the monetary or non-monetary value of the benefit.

### Basic Value Structure

```json
{
  "amount": 300,
  "currency": "USD",
  "type": "credit"
}
```

### Value Fields
- **amount** (number, optional): Monetary amount. Use `0` or `null` for non-monetary benefits.
- **currency** (string, required): Currency code (typically `"USD"`).
- **type** (string, required): Value type. Common values:
  - `"credit"` - Statement credit or discount
  - `"membership"` - Membership benefit (no monetary value)
  - `"bonus"` - Bonus earning rate
  - `"discount"` - Discount or fee waiver
  - `"other"` - Other types

### Additional Value Fields (Optional)

#### Frequency
For recurring benefits:
```json
{
  "amount": 5,
  "currency": "USD",
  "type": "credit",
  "frequency": "monthly"
}
```
- **frequency** (string, optional): `"monthly"`, `"annual"`, `"semi_annual"`, `"quarterly"`

#### Validity Period
For benefits with longer validity:
```json
{
  "amount": 100,
  "currency": "USD",
  "type": "credit",
  "validityPeriod": "4_years"
}
```
- **validityPeriod** (string, optional): Duration like `"4_years"`, `"2_years"`, etc.

#### Special Months
For benefits with different amounts in specific months:
```json
{
  "amount": 15,
  "currency": "USD",
  "type": "credit",
  "frequency": "monthly",
  "specialMonths": {
    "12": 35
  }
}
```
- **specialMonths** (object, optional): Map of month number (1-12) to amount. Example: December gets $35 instead of $15.

#### Bonus Category Caps
For bonus earning categories:
```json
{
  "amount": 0,
  "currency": "USD",
  "type": "bonus",
  "maxSpend": 1500,
  "maxReward": 75
}
```
- **maxSpend** (number, optional): Maximum spending that earns bonus (in currency units).
- **maxReward** (number, optional): Maximum reward amount (in currency units).

---

## Important Notes

### Expiration Dates
- **Monthly benefits**: Expire on the **last day of each month** (not the reminder day).
- **Quarterly benefits**: Expire on the **last day of each quarter month**.
- **Annual benefits**: Expire on the **last day of the anniversary month** (not the anniversary day).
- **Semi-annual benefits**: Expire on the **last day of the semi-annual period month**.
- **One-time benefits**: Use the specified date as expiration.

### Card Anniversary
- Annual and quarterly benefits use the card's `cardAnniversaryDate` (set by user when adding card).
- If not specified, defaults to the date the card was added.

### Image URLs
- Card images should be placed in the `Card_Pictures/` directory.
- Use the full GitHub raw URL format:
  ```
  https://raw.githubusercontent.com/USERNAME/REPO/main/Card_Pictures/filename.jpg
  ```

### IDs
- Card and benefit IDs should be:
  - Lowercase
  - Use underscores for spaces
  - Unique across all cards/benefits
  - Descriptive (e.g., `"chase_sapphire_reserve"`, `"travel_credit_annual"`)

### Schema Version
- Increment `schemaVersion` when making breaking changes to the structure.
- Update `lastUpdated` timestamp whenever the file is modified.

---

## Examples

### Example 1: Monthly Credit

```json
{
  "id": "uber_credit",
  "name": "Uber Cash Credit",
  "description": "$15 monthly Uber credit ($35 in December)",
  "category": "Transportation",
  "value": {
    "amount": 15,
    "currency": "USD",
    "type": "credit",
    "frequency": "monthly",
    "specialMonths": {
      "12": 35
    }
  },
  "reminder": {
    "type": "monthly",
    "dayOfMonth": 1,
    "message": "Use your $15 Uber credit this month! ($35 in December)"
  },
  "usageTracking": {
    "enabled": true,
    "resetPeriod": "monthly"
  }
}
```

### Example 2: Annual Credit

```json
{
  "id": "travel_credit_annual",
  "name": "$300 Annual Travel Credit",
  "description": "Automatically applied to travel purchases. Resets annually on card anniversary.",
  "category": "Travel",
  "value": {
    "amount": 300,
    "currency": "USD",
    "type": "credit"
  },
  "reminder": {
    "type": "annual",
    "startDate": "card_anniversary",
    "daysBefore": 30,
    "message": "Don't forget to use your $300 travel credit before it resets!"
  },
  "usageTracking": {
    "enabled": true,
    "resetPeriod": "annual"
  }
}
```

### Example 3: Quarterly Bonus

```json
{
  "id": "quarterly_bonus",
  "name": "5% Quarterly Bonus Categories",
  "description": "Earn 5% cash back on rotating categories (up to $1,500 per quarter)",
  "category": "Cashback",
  "value": {
    "amount": 0,
    "currency": "USD",
    "type": "bonus",
    "maxSpend": 1500,
    "maxReward": 75
  },
  "reminder": {
    "type": "quarterly",
    "startMonth": 1,
    "dayOfMonth": 1,
    "message": "Check this quarter's 5% bonus categories and activate them!"
  }
}
```

### Example 4: Semi-Annual Credit

```json
{
  "id": "saks_credit",
  "name": "Saks Fifth Avenue Credit",
  "description": "$50 credit every 6 months (January-June and July-December)",
  "category": "Shopping",
  "value": {
    "amount": 50,
    "currency": "USD",
    "type": "credit",
    "frequency": "semi_annual"
  },
  "reminder": {
    "type": "semi_annual",
    "periods": [
      {
        "startMonth": 1,
        "endMonth": 6
      },
      {
        "startMonth": 7,
        "endMonth": 12
      }
    ],
    "dayOfMonth": 1,
    "message": "Use your $50 Saks credit for this half of the year!"
  },
  "usageTracking": {
    "enabled": true,
    "resetPeriod": "semi_annual"
  }
}
```

### Example 5: Membership Benefit

```json
{
  "id": "priority_pass",
  "name": "Priority Pass Select Membership",
  "description": "Complimentary access to 1,300+ airport lounges worldwide",
  "category": "Travel",
  "value": {
    "amount": 0,
    "currency": "USD",
    "type": "membership"
  },
  "reminder": {
    "type": "one_time",
    "date": "2025-01-15",
    "message": "Activate your Priority Pass membership to access airport lounges"
  }
}
```

### Example 6: Complete Card Entry

```json
{
  "id": "amex_platinum",
  "name": "American Express Platinum",
  "issuer": "American Express",
  "cardNetwork": "Amex",
  "category": "premium_travel",
  "imageUrl": "https://raw.githubusercontent.com/Jinkehan/Jin-s-Credit-Card-Manager/main/Card_Pictures/Amex_Platinum.jpeg",
  "defaultBenefits": [
    {
      "id": "uber_credit",
      "name": "Uber Cash Credit",
      "description": "$15 monthly Uber credit ($35 in December)",
      "category": "Transportation",
      "value": {
        "amount": 15,
        "currency": "USD",
        "type": "credit",
        "frequency": "monthly",
        "specialMonths": {
          "12": 35
        }
      },
      "reminder": {
        "type": "monthly",
        "dayOfMonth": 1,
        "message": "Use your $15 Uber credit this month! ($35 in December)"
      },
      "usageTracking": {
        "enabled": true,
        "resetPeriod": "monthly"
      }
    },
    {
      "id": "airline_fee_credit",
      "name": "Airline Fee Credit",
      "description": "$200 annual credit for airline incidental fees with selected airline",
      "category": "Travel",
      "value": {
        "amount": 200,
        "currency": "USD",
        "type": "credit"
      },
      "reminder": {
        "type": "annual",
        "startDate": "card_anniversary",
        "daysBefore": 60,
        "message": "Don't forget to use your $200 airline fee credit!"
      },
      "usageTracking": {
        "enabled": true,
        "resetPeriod": "annual"
      }
    }
  ]
}
```

---

## Quick Reference

### Reminder Type Summary

| Type | Expiration Date | Required Fields |
|------|----------------|-----------------|
| `monthly` | Last day of month | `dayOfMonth`, `message` |
| `annual` | Last day of anniversary month | `startDate: "card_anniversary"`, `daysBefore`, `message` |
| `quarterly` | Last day of quarter month | `message` (optional: `startMonth`, `dayOfMonth`) |
| `semi_annual` | Last day of period month | `periods`, `message` (optional: `dayOfMonth`) |
| `one_time` | Specified date | `date`, `message` |

### Common Categories

**Card Categories:**
- `premium_travel`, `cashback`, `rewards`, `travel`, `store`, `financing`

**Benefit Categories:**
- `Travel`, `Dining`, `Shopping`, `Cashback`, `Transportation`, `Other`

**Value Types:**
- `credit`, `membership`, `bonus`, `discount`, `other`

---

## Editing Workflow

1. **Open** `card-benefits.json` in a JSON editor (with syntax validation).
2. **Update** `lastUpdated` timestamp to current date/time (ISO 8601 format).
3. **Make changes**:
   - Add new cards to `predefinedCards` array
   - Add benefits to a card's `defaultBenefits` array
   - Modify existing card/benefit fields
4. **Validate JSON** syntax (ensure proper commas, brackets, quotes).
5. **Test** by committing and pushing to GitHub (app will fetch updated data).

---

## Troubleshooting

### Common Issues

1. **JSON Syntax Errors**
   - Missing commas between array/object elements
   - Unclosed brackets or braces
   - Unescaped quotes in strings
   - Use a JSON validator before committing

2. **Missing Required Fields**
   - All required fields must be present (see field descriptions above)
   - Optional fields can be omitted or set to `null`

3. **Invalid Dates**
   - Use ISO 8601 format: `"YYYY-MM-DD"` or `"YYYY-MM-DDTHH:MM:SSZ"`
   - For `one_time` reminders, use date only: `"2025-01-15"`

4. **Invalid IDs**
   - Must be unique
   - Use lowercase with underscores
   - No spaces or special characters

---

## Need Help?

Refer to existing entries in `card-benefits.json` for reference patterns. The file contains examples of all reminder types and value configurations.
