# stopwatch

This project is a stopwatch. This sounds deceptively simple, so a walkthrough of the early choices of the hows is in order. Let this readme be that guide.

This readme assume you have read the code, and have questions about it. This readme tries its best to guess those questions and answer them.

* Why question - answers and not a simple "start here" document?
  * Having to read the code first and formulate your questions speeds up understanfing and familiarisation, both of them are valuable in this long-lived enterprise project
* Why bother with the timestamps and not just run a Timer?
  * In short, that's fragile in multiple ways:
    * The host OS can decide anytime it suspends our apps code execution
    * Timer clock can have slight inaccuracies that compound over time
    * We cannot expect the user to keep our app in foreground for the whole usage session. What if a call comes in? The battery dies, etc...
    * For the reason above, we need persistence. Persisting a Timer is excessive IO writes in the case of a Stopwatch
* Why hide some buttons at different point of the user journey and not display all of them all the time, like it is written in the requirements?
  * It guides the user to only take valid actions. However, the viewmodel does not rely on this fact, all public methods defend against calls in invalid states with early returns
* Why let the user take a lap while the stopwatch is paused? Ain't that complicates things a bunch?
  * Well, yes it does, but i tought this is a more forgiving behavior. if the user presses the wrong button wanting to record a Lap, they can still do it and the time of the lap remains accurate
* What happens if the stopwatch runs over 100 minutes? You only got two digits there, thats 99 tops
  * Nope, it displays it no problemo
* Why include a whole history section? It wasn't in the brief?
  * Well i tought since we already have persistence, this could make a nice addition. Of course, in a real day-to-day working scenario i woudl just propose it in a meeting instead of just implementing them.
* So tell me about those di1,2,3 and 4 files. What happened there?
  * As the only oral guidance for this project i recieved from my boss was: "He said do it like you are working for us", abd since you mentioned you roll your own things for just about everything, I tought I take this as an opportunity to make my own riverpod-style DI conatiner, just to make things fun for myself. It turns out, replicating the most used di package is not a one day funride, rather a multi day fun-grind. I sank 3 days into this before I decided it was taking too long for this assignment. In DI4 i vibecoded it to completion, just to see how that would look. I havent used it, as this was not the main task and I didn't wanted to waste more time debugging this layer. But as I allocated time to it in this assignment, i tought i leave it there to see, despite it's not being a home run.
* I see a bunch of comments about future ideas and upgrades, Why didn't you just implemented them?
  * Because of time, again. I hinted things i would do if this was a real project, but as an assignment, i decided to omit a few things that are not challanging and only nice to have, like the nicely formatted DateTime in the history section, or the staggered delete animation on the lap list. I think we both agree i could do those, so i havent spent time actually doing them, but i wanted to mention that i see space for future improvement there.
* Speaking of future improvements...
  * Yeah, i can think a couple of those:
    * Fake out the hundreds of seconds counter while it's running and only displaying real value when it's stopped. that would slash notifier rebuild frequency by 10x
    * I dont like the *currentRoundModel* in the stopwatch_view_model, it transgresses the single source of thruth, duplicates things in the DB. I contemplated using a streaming database instead of the sqlite/riverpod combo. That would leave us with one less dependency and a true single source of thruth. I decided against it bc no streaming acid compliant db hasd enough recognition on pub.dev to include it as a cornerstone in an 'enterprise level' application.
    *
