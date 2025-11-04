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

## Current Feature: Camera Capture Module

This section details the plan and implementation of the recently added camera capture functionality, designed to make data acquisition faster and more direct.

### Objective

To integrate a new, independent module that allows users to capture images and videos directly from the device's camera into an active project, complete with advanced controls for a better capture experience.

### Implementation Plan & Features

1.  **Dependencies Added:**
    *   `camera`: The core package for controlling the device camera hardware.
    *   `wakelock`: To prevent the screen from sleeping during capture sessions.
    *   `permission_handler`: To robustly request and manage camera and microphone permissions.

2.  **Modified Entry Point:**
    *   The "Add Images" `FloatingActionButton` on the `ProjectScreen` was updated.
    *   It now opens a `showModalBottomSheet` presenting three clear options: "From Files", "From Folder", and the new "Use Camera".

3.  **Independent Camera Module (`lib/ui/screens/camera/camera_screen.dart`):
    *   **Self-Contained:** All camera logic is encapsulated within this new screen to avoid altering existing code.
    *   **Permission Handling:** The screen first requests camera and microphone permissions. If denied, it shows an informative message with a shortcut to the app's settings.
    *   **Screen Lock:** `Wakelock` is enabled when the screen is active and disabled when it's closed to ensure uninterrupted use.
    *   **Dual Mode:** Users can switch between a "Photo" mode and a "Video" mode.
    *   **Advanced Controls (Photo Mode):**
        *   **Zoom:** A slider allows for smooth control of the camera's zoom level.
        *   **Timer:** A slider sets an interval (in seconds) for automatic, periodic photo capture.
    *   **Capture & Recording:**
        *   A central button handles all actions: take a photo, start/stop auto-capture, or start/stop video recording.
    *   **File Organization:**
        *   Captured **images** are saved directly to the project's `images/` folder.
        *   Recorded **videos** are saved to a new `videos/` folder within the project, which is created if it doesn't exist.

4.  **Seamless Integration:**
    *   Upon closing the camera screen, a callback is triggered that automatically refreshes the `ProjectScreen`, making newly captured images immediately visible in the project's image grid.
