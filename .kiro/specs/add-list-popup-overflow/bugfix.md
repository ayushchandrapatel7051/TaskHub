# Bugfix Requirements Document

## Introduction

The "Add List" popup dialog in the TaskHub sidebar overflows beyond the right edge of the application window. The popup has a fixed width of 740px and is positioned by a centering function that does not properly constrain the right boundary. On windows narrower than the popup width, or when the centering calculation places the popup too far right, the dialog content spills outside the visible window bounds. The fix must ensure the popup is always fully visible within the application window and properly centered.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the application window width is less than or equal to the popup width (740px) plus margins THEN the system renders the "Add List" popup extending beyond the right edge of the window

1.2 WHEN the `openCenteredPopup` function calculates the popup's x position THEN the system does not clamp the right boundary, allowing `popup.x + popup.width` to exceed `Overlay.overlay.width`

1.3 WHEN the "Add List" popup is opened on a window of any size THEN the system may display dialog content that is visually cut off or inaccessible outside the window bounds

### Expected Behavior (Correct)

2.1 WHEN the application window width is less than or equal to the popup width plus margins THEN the system SHALL constrain the popup within the window bounds, scaling or repositioning it so no content overflows the right edge

2.2 WHEN the `openCenteredPopup` function calculates the popup's x position THEN the system SHALL clamp the result so that `popup.x + popup.width` does not exceed `Overlay.overlay.width - margin`

2.3 WHEN the "Add List" popup is opened on a window of any size THEN the system SHALL display the entire popup dialog within the visible window area

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the application window is wide enough to fully contain the popup (width > 740px + margins) THEN the system SHALL CONTINUE TO center the popup horizontally within the window

3.2 WHEN the "Add List" popup is opened THEN the system SHALL CONTINUE TO center the popup vertically within the window

3.3 WHEN the user interacts with the "Add List" popup (entering a name, selecting color, folder, list type) THEN the system SHALL CONTINUE TO function correctly and create the list on confirmation

3.4 WHEN other popups (newFolderPopup, newTagPopup, accountPopup) are opened via `openCenteredPopup` THEN the system SHALL CONTINUE TO position them correctly within the window bounds
