# Cycling Goals for Garmin

Cycling Goals for Garmin is a Garmin Connect IQ app for Edge cycling computers. It will help riders understand whether they are on pace for annual, monthly, and weekly distance and elevation-gain goals—and what average they need from today forward to finish each goal.

## Planned goals

- Annual distance and elevation gain
- Monthly distance and elevation gain
- Weekly distance and elevation gain

For each goal, the app is intended to show progress, remaining amount, percentage complete, expected progress today, ahead/behind pace, original required pace, and required pace from today forward.

## Project status

Initial Connect IQ project skeleton only. Product behavior and Garmin-specific architecture have not yet been implemented.

Before implementation, the project still needs decisions about:

- Connect IQ app type and user experience
- Supported Edge models
- Goal configuration
- Activity and progress data source
- Canonical goal-calculation edge cases

## Development prerequisites

Install the Garmin Connect IQ SDK and configure a developer key. The project uses Monkey C and the standard Connect IQ project layout.

The current manifest provisionally defines a standalone Connect IQ device app and targets Edge 540, 840, 1040, and 1050. Those choices should be reviewed before feature development.
