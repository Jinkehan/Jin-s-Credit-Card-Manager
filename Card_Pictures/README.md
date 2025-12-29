# Card Pictures

## Overview
This folder contains card images that are automatically fetched and cached by the app from GitHub. The app downloads images on-demand and stores them locally for offline access.

## Current Images
- `Amex_Platinum.jpeg` - American Express Platinum card image

## How It Works

### Automatic Image Fetching
1. **On App Launch**: When the app fetches card benefits from GitHub, it also downloads associated card images
2. **Local Caching**: Images are automatically saved to the device's Documents directory
3. **Offline Support**: Cached images are available even when there's no internet connection
4. **Auto-Update**: When new images are pushed to GitHub, the app will automatically download and cache them

### Image Storage
- **Remote**: Images are stored on GitHub at `https://raw.githubusercontent.com/Jinkehan/Jin-s-Credit-Card-Manager/main/Card_Pictures/`
- **Local**: Images are cached in the app's Documents directory under `CardImageCache/`

## Adding New Card Images

### Step 1: Add Image to Repository
1. Place the card image in this `Card_Pictures` folder
2. Name it descriptively (e.g., `Chase_Sapphire_Reserve.jpeg`, `Amex_Platinum.jpeg`)
3. Commit and push to GitHub

### Step 2: Update card-benefits.json
Add the `imageUrl` field to the card entry:

```json
{
  "id": "amex_platinum",
  "name": "American Express Platinum",
  "issuer": "American Express",
  "cardNetwork": "Amex",
  "category": "premium_travel",
  "imageUrl": "https://raw.githubusercontent.com/Jinkehan/Jin-s-Credit-Card-Manager/main/Card_Pictures/Amex_Platinum.jpeg",
  "defaultBenefits": [
    ...
  ]
}
```

### Step 3: Push Changes
Once you push both the image and the updated JSON to GitHub, the app will automatically:
- Fetch the new card data
- Download the card image
- Cache it locally
- Display it in the Test Card Benefits page

## Image Requirements

- **Format**: JPEG or PNG
- **Recommended Aspect Ratio**: 1.6:1 (standard credit card ratio)
- **Recommended Size**: 300x188 pixels minimum for good quality
- **File Size**: Keep images under 500KB for faster downloads
- **Naming**: Use descriptive names with underscores (e.g., `Amex_Platinum.jpeg`)

## Testing

After pushing changes:
1. Open the app
2. Navigate to Settings > Test Card Benefits
3. Pull to refresh or tap the refresh button
4. Card images should automatically download and appear
5. A loading spinner shows while images are downloading
6. If an image fails to load, a blue placeholder icon appears

## Cache Management

The app automatically manages the image cache:
- Images persist between app launches
- Cache is stored in the app's Documents directory
- Can be cleared programmatically if needed
- Images are re-downloaded if the cache is cleared

## Troubleshooting

### Image Not Appearing
1. Check that the image file exists in GitHub at the correct URL
2. Verify the `imageUrl` in `card-benefits.json` is correct
3. Check network connectivity
4. Try force-refreshing in the Test Card Benefits page
5. Look for error messages in Xcode console

### Image Quality Issues
- Ensure source image is at least 300x188 pixels
- Use JPEG quality of 80-90% to balance size and quality
- Avoid overly compressed images

### Slow Loading
- Reduce image file size (compress before uploading)
- Ensure stable internet connection
- Images are cached after first download for faster subsequent loads

## Technical Details

### Image Cache Service
The `ImageCacheService` handles all image operations:
- **Fetching**: Downloads images from GitHub URLs
- **Caching**: Saves images to local storage
- **Memory Management**: Keeps frequently used images in memory
- **Prefetching**: Downloads all card images in parallel after fetching benefits

### URL Format
```
https://raw.githubusercontent.com/USERNAME/REPO_NAME/BRANCH/Card_Pictures/IMAGE_NAME.jpeg
```

### Cache Location
```
~/Documents/CardImageCache/[card_id].jpg
```

## Benefits of This Approach

✅ **Easy Updates**: Just push images to GitHub - no app rebuild needed  
✅ **Offline Support**: Images work without internet after first download  
✅ **Automatic Sync**: App stays up-to-date with latest card images  
✅ **Efficient**: Images are downloaded once and cached locally  
✅ **Scalable**: Can easily add hundreds of card images without app size impact  
