# VibeTrack

voice → nutrition data → charts. just vibe with your food tracking.

## what it does

talk to your phone about what you ate. claude figures out the calories and macros. see pretty charts of your eating patterns. that's it.

built in swift because why not. uses anthropic's api to parse natural speech into structured nutrition data.

## features

- **voice input**: "had a big mac and fries for lunch" → parsed nutrition data
- **manual backup**: can type instead of talking
- **smart parsing**: handles relative times ("yesterday morning"), portion sizes, multiple foods
- **local storage**: your data stays on device
- **charts**: see your patterns over time
- **edit anything**: ai made assumptions? fix them

## the vibe

this was mostly a one-shot prompt experiment. asked claude to build a nutrition tracker, it built... this entire app. the voice parsing actually works surprisingly well.

no subscriptions, no accounts, no bs. just a tool that does what it says.

## setup

1. clone this
2. add your anthropic api key to `Config/Config.xcconfig`:
   ```
   ANTHROPIC_API_KEY = your_key_here
   ```
3. open in xcode
4. run on device (voice stuff needs real hardware)

## tech stack

- swiftui for ui
- speech framework for voice input
- anthropic claude api for parsing
- swift charts for visualizations
- core data would be overkill so just userdefaults

## why

nutrition tracking apps are either too complicated or too simple. wanted something that just works with natural speech. turns out llms are pretty good at "2 eggs and toast" → structured data.

also wanted to see what you could build with one really good prompt.

## contributing

sure, send prs. keep it simple though.

## license

mit or whatever. it's just code.
