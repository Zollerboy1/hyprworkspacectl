# hyprworkspacectl

This little CLI tool simplifies controlling hyprland workspaces on multi-monitor setups.

## Installation

Clone this repository and build it using `swift build -c release`.
Now copy the executable `.target/debug/hyprworkspacectl` to somewhere in your `$PATH`.

## Usage

You can list existing workspaces using the `list` command:

```bash
hyprworkspacectl list
```

You can move to a workspace using the `move` command:

```bash
hyprworkspacectl move <workspace>
```

where `<workspace>` can either be the name or integer ID of an existing workspace, or the string `left` or `right`.

The `left` and `right` workspaces specify the next workspaces to the left/right on the currently active monitor.
Moving to the `right` workspace also creates a new workspace with an incresing integer ID, if the rightmost workspace is already active on the current monitor.
