# Stopwatch

The aim for this project is to give the users a durable, fault tolerant, performant stopwatch for their time measuring needs.

## Setup:

Use flutter >= 3.44.0 (or fvm)

If primary constructors are not stable yet, you need these run args too:

```
      "--enable-experiment=primary-constructors",
      "--extra-front-end-options=--enable-experiment=primary-constructors"
```

## Architecture:

The project utilizes the MVVM architecture for maximum testability and lean data flow.
