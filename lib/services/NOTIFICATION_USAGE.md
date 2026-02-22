## Notification Service Usage Guide

The `NotificationService` provides a unified way to show toast messages and snackbars throughout your app using Flutter Toast.

### Toast Messages

Toast messages are lightweight notifications that appear briefly on screen:

```dart
// Basic toast
NotificationService.showToast('Simple message');

// Predefined toast types
NotificationService.showSuccessToast('Operation completed successfully!');
NotificationService.showErrorToast('An error occurred');
NotificationService.showWarningToast('Please check your input');
NotificationService.showInfoToast('New update available');

// Custom toast with specific positioning
NotificationService.showToast(
  'Custom toast',
  gravity: ToastGravity.TOP,
  backgroundColor: Colors.purple,
  fontSize: 18.0,
);
```

### Snackbar Messages

Snackbar messages appear at the bottom of the screen and can include actions:

```dart
// Basic snackbar
NotificationService.showSnackBar(context, 'This is a snackbar');

// Predefined snackbar types
NotificationService.showSuccessSnackBar(context, 'Profile saved successfully!');
NotificationService.showErrorSnackBar(context, 'Failed to connect to server');
NotificationService.showWarningSnackBar(context, 'Data will be lost');
NotificationService.showInfoSnackBar(context, 'New feature available');

// Snackbar with action
NotificationService.showSnackBar(
  context,
  'Item deleted',
  action: SnackBarAction(
    label: 'UNDO',
    onPressed: () {
      // Handle undo action
    },
  ),
);
```

### Migration from ScaffoldMessenger

Replace all instances of:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message')),
);
```

With:
```dart
// For toast messages (recommended)
NotificationService.showToast('Message');

// Or for snackbar messages
NotificationService.showSnackBar(context, 'Message');
```

### Features

- **Unified API**: Single service for all notifications
- **Predefined types**: Success, Error, Warning, Info
- **Customizable**: Colors, positioning, duration
- **Toast & Snackbar**: Both notification types supported
- **Context-free**: Toast messages don't require BuildContext

### Color Scheme

- **Success**: Green (#4CAF50)
- **Error**: Red (#F44336)
- **Warning**: Orange (#FF9800)
- **Info**: Blue (#2196F3)
