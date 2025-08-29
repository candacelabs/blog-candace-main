---
title: "welcome to candaceserver on candace.cloud"
---

## background

- undergrad: [cmu](https://www.cmu.edu/), 2021
- physical location: san francisco, ca
- trade: software

## please find me on

- [linkedin](https://linkedin.com/in/kaashmonee): kaashmonee
- [github](https://github.com/kaashmonee): kaashmonee
- [candace github](https://github.com/candacelabs): candacelabs
- [resume](https://docs.google.com/document/d/1P8LsmdQ1ZsWUwE8tb2j5lexbQHrQauMWCSgeGFumirE/edit?usp=sharing)
- [codeforces](https://codeforces.com/kaashmonee): @kaashmonee

## what am i looking at

candaceserver is an experiment in hosting in the age of AI vibecoding:

> "Vibe coding menugen was exhilarating and fun escapade as a local demo, but a bit of a painful slog as a deployed, real app. Building a modern app is a bit like assembling IKEA future. There are all these services, docs, API keys, configurations, dev/prod deployments, team and security features, rate limits, pricing tiers... Meanwhile the LLMs have slightly outdated knowledge of everything, they make subtle but critical design mistakes when you watch them closely, and sometimes they hallucinate or gaslight you about solutions. But the most interesting part to me was that I didn't even spend all that much work in the code editor itself. I spent most of it in the browser, moving between tabs and settings and configuring and gluing a monster. All of this work and state is not even accessible or manipulatable by an LLM - how are we supposed to be automating society by 2027 like this?"

- [andrej karpathy, twitter, 2025](https://x.com/karpathy/status/1917961248031080455)

growing up i never had an opportunity to go through a goth phase. i wasn't allowed to wear ripped pants in my house.
but i think it's time to embrace my inner goth now. that is to say, i also use candaceserver
as a means of experimenting with the [GOTTH](https://github.com/TomDoesTech/GOTTH) stack, which i think solves a lot of issues of modern day web dev that causes the problems that karpathy talks about above, like:

1. build bloat
2. framework bloat
3. superfluous client-side state management (do we *really* need redux if most of us now, unlike in 2012, have fiber access with gigabit download speeds?)
4. vibecoding currently not fun
5. runtime bloat, microservice hell, and vendor lockin
    - "man i need concurrency"
    - "ok sure here's some concurrency"
    - "can i also get some parallelism"
    - "we have parallelism at home"
    - parallelism at home:
        - celery + redis + multiple asgi/python runtimes
        - = multiple compute instances means more infrastructure to manage
        - = more infrastructure to manage means unnecessary microservices
        - = unnecessary microservices means hemhorraging costs
        - = exacerbates cycle of predatory cloud pricing and anti-competitive vendor lock-in practices
        - = culminates in long term deterioration of software quality and human quality of life in an increasingly software-centric world
        - all of this just...to use the cpu cores i already paid for...?
6. want serverside rendering but don't to be chained to v0 + vercel + aws oligopoly

## apps

1. [007](https://candace.cloud/007): encrypted, in-memory secret sharing service
2. [pastebin clone](https://candace.cloud/paste): encrypted, in-memory pastebin clone

### how does this work?

infrastructure stack:

1. default ATT home internet gateway, seems ok for now, capable of handling 30k+ entries in NAT table
2. rate limited and ip-blacklisted caddy reverse proxy container with LAN/WAN bridge
    a. i did get DOS'd once! that was pretty cool. added rate limiting -- never happened again
3. docker compose managed services

    1. prometheus/grafana for observability/monitoring for pretty much every service. an example for peeking at the health of the Caddy reverse proxy (not exposed to the internet)

    {{< figure src="image-1.png" alt="alt text" width="100%" >}}

    2. GOTTH app gateway container for vibecoded app experimentation + internal Golang library for rapdily spinning up production-ready services instrumented with proper logging and metrics scraping (not yet open source)

        1. leverages Golang runtime, fast compilation, *extremely prescriptive and opinionated ethos* to make vibecoding literally work the first time you do it (nearly impossible to vibecode "bad"/"unidiomatic" Go code. i love opinionated langauges! don't let developers make decisions!)

    3. [Hugo](https://gohugo.io/) blogging container (which is where you're reading this post)

    4. jellyfin container for media management

    5. some other extra containers (additional details can be provided upon signing NDA)

4. [candacecli](https://github.com/candacelabs/cli)

5. DNS: cloudflare

### hardware infrastructure details

- dell optiplex minipc
- 32 gb ram
- 4 cpu cores
- intel integrated graphics

### software infrastructure details

- LVM encrypted
- ubuntu server LTS

### some guidelines i try to stick to

1. dev/prod parity: dev environments and testing environments are containerized. no surprises going to prod
2. separate dev instance for testing: <https://dev.candace.cloud>
3. vibecode when possible: if vibecoding is not easy, modify infrastructure to reduce ambiguity
4. test fast and often without affecting live "instance"
5. single-instance development, testing, and deployment
6. don't need to back up: lost data should be easily recoverable. don't store super sensitive personal data (e.g., no saving wallet addresses with $2M in fartcoin)
7. encrypted when possible end-to-end
8. version control everything (a new candace server takes ~5 minutes to spin up once you have a VPS or port-forwarding done)
9. all custom services are:
    1. GOTTH (doesn't apply to candacecli, for example, which is in python)
    2. immediately observable/monitor-able
    3. well documented (AI should be prompted like "i'm new and i don't know what i'm doing explain why you write the code you do, how it works, and how it should be tested")
    4. contains CLAUDE.md
    5. vibecode-able

try clicking on a post to see the clean interface, then come back here for the terminal vibes!
