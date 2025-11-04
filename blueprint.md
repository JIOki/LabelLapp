# Blueprint: BBox Annotator

## Overview

This document outlines the project structure, features, and design principles of the BBox Annotator application. It serves as a single source of truth for the app's capabilities and architecture, and is updated with each new feature implementation.

## Core Features

BBox Annotator is a Flutter-based mobile tool for creating image annotation datasets for object detection models.

*   **Project Management:**
    *   Create, list, search, and delete annotation projects.
    *   Each project has a name, a location on the device, and a defined set of class labels.
*   **Image Handling:**
    *   Import images into a project from the device's file system (single files or entire folders).
    *   View imported images in a grid layout.
*   **Annotation:**
    *   A dedicated annotation screen allows users to draw bounding boxes on images.
    *   Each box is assigned a class from the project's label list.
*   **Data Export:**
    *   Export projects as a ZIP file containing the images and corresponding label files in YOLO format.
    *   Includes a `classes.txt` file with the list of labels.
*   **Modern User Experience:**
    *   A visually appealing UI with a subtle background texture and custom project cards.
    *   Support for both light and dark modes, with a theme toggle.
    *   Uses modern, clean typography (`GoogleFonts`).

---

## Current Feature: Horizontal Annotation Interface

This section details the plan and implementation of the redesigned annotation screen, which is now optimized for a horizontal (landscape) layout to enhance user experience.

### Objective

To improve the usability of the `AnnotationScreen` by forcing a landscape orientation. This maximizes the image viewing area, reduces wasted space, and provides a more ergonomic layout for annotating images.

### Implementation Plan & Features

1.  **Forced Landscape Orientation:**
    *   The `AnnotationScreen` now automatically forces the device into landscape mode upon entry using `SystemChrome.setPreferredOrientations`.
    *   The orientation is reset to the user's preferred settings when the screen is closed, ensuring no impact on the rest of the application.

2.  **Redesigned Horizontal Layout:**
    *   The screen's layout has been fundamentally changed from a vertical `Column` to a horizontal `Row`.
    *   **Image Viewer (Expanded):** The main area is now an expanded `PageView` that displays the image, making full use of the horizontal space.
    *   **Side Control Panel:** A new, fixed-width panel has been added to the right side of the screen to house all interactive controls.

3.  **Ergonomic Control Panel:**
    *   All annotation controls have been consolidated into the new side panel for easy access:
        *   **Top Bar:** Contains the 'Back' button, the current image name, and the 'Save' button.
        *   **Image Navigation:** Explicit 'Previous' (`<`) and 'Next' (`>`) buttons have been added for clear, easy navigation between images, complementing the existing swipe gesture.
        *   **Class Selector:** The list of class `ChoiceChip`s is now vertically scrollable within the panel.
        *   **Annotation Actions:** 'Undo' and 'Redo' buttons are placed at the bottom of the panel.

4.  **Seamless Functionality:**
    *   The core logic for drawing, saving, auto-saving on swipe/navigation, and state management remains intact.
    *   The new layout is fully responsive and provides a more intuitive and efficient annotation workflow.
