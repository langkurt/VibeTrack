# VibeTrack TODO List

## High Priority
- **Push to GitHub** - Need instructions on how to create the GitHub repo and link the existing local repo to it. I always forget. SSH preferred.

- **Fix web search tool** - I don't think the agent web search tool is working. I think the LLM is just pulling data from its training. Tool use might need to be explicitly allowed in the API call/prompt. See: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/web-search-tool#how-to-use-web-search

- **Log user inputs and AI outputs** - All of them. Have a place in the app to view it (small button, used for development to quickly see logs about what's going on).

- **Edit food items with swipe gesture** - If you slide from left to right you should be able to speak to edit. The new data and old data are both sent to the AI API.

- **Write an actual README** - Not a todo list lmao.

## Medium Priority
- **Semantic caching for responses** - Users will most likely eat the same things multiple times. Need to design this to flesh out the idea. There are a couple papers worth reading on this because semantic caching is storing the user's *intent* not just the hashed input verbatim. So "avocado toast" and "toast with avocado" are both the same and a cache hit. Anthropic has prompt caching, but is invalidated after 5 minutes. I would rather have something like a two-layer space-constrained cache. L1 would be smaller and per user, and L2 would be app-wide and larger. If both miss, then I guess go ask the LLM :)

- **Cloud storage for user data/telemetry** - Need to set up a cloud solution for receiving and analyzing telemetry. User I/O, failure rate, edit rate, user sentiment (frustrated, etc). Considering Azure Event Hubs and Service Bus since I have some Azure credits to use. Building it out with some Bicep declarative IaC would be good.

- **Store input/output for AI responses** - Evaluate those and make sure they are not deviating. Create the curated dataset based on if they are good or not, then train the SLM to check all responses and report success metrics. Can we run these evals in a batch on a spot instance or slower Azure Functions?

## Low Priority
- **Offline handling** - Store unsent requests and play them back once connectivity is restored. This should be relatively easy.

- **Suggested eating times and amounts** - Based on learned behavior and weight loss goals. Need to think and design what this feature even is. Is it notifications? Is it linear regressions on the user's chart data?

- **Fine-tuned small language model** - To do all the analysis on the device. Can make calls to the LLM if SLM can't figure it out or needs function calling (search). This needs research.
