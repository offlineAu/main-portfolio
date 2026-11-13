# The Veloce case study is told as a walk through the product: acts group steps, and each step
# pairs one screenshot (app/assets/images/veloce) with a short caption. Copy describes only what
# the screenshots show; it makes no claims about clients, traffic, or results.
module VeloceStoryHelper
  VELOCE_STORY = [
    { id: "first-impression", title: "The first impression", steps: [
      { image: "01-hero", ratio: "16 / 10", heading: "Websites that work for your business.",
        body: "The homepage leads with one promise and one next step, requesting a meeting. Beside it, a sample build plays on a laptop and phone, switchable between a website, an online store and a business system.",
        alt: "Veloce homepage reading “Websites that work for your business” beside a laptop and phone showing a sample advisory-firm site, with Website, Online store and Business system toggles" },
      { image: "02-workarounds", ratio: "16 / 10", heading: "Start from the problem.",
        body: "“Most businesses run on workarounds”: booking requests scattered across messages, approvals tracked in spreadsheets and email, a website that hasn’t kept up. A dark panel answers each one with a single working system.",
        alt: "A section titled “Most businesses run on workarounds” listing three problems, next to a dark panel reading “We turn them into one working system”" },
      { image: "03-examples", ratio: "16 / 10", heading: "Picture it working.",
        body: "A carousel of seven sample websites, stores and business tools. Each one can be opened as a live preview or used as the starting design in the builder.",
        alt: "The “Picture it working” carousel on sample 1 of 7, an advisory-firm website, with buttons to view a live preview or start from this design" }
    ] },
    { id: "explore-services", title: "Explore the services", steps: [
      { image: "04-services", ratio: "16 / 10", heading: "Choose what needs to change first.",
        body: "Services are grouped by need, reaching customers or running the day-to-day, in a contents list beside an open service book. Each page answers one need and ends with “Ask about this.”",
        alt: "A section titled “Choose what needs to change first” with a grouped services list beside an open book on its Business websites page" },
      { image: "05-service-page", ratio: "16 / 10", heading: "A page for every service.",
        body: "Each service gets its own page, like business websites: what it does for a customer, in plain language, and a direct way to discuss the project.",
        alt: "The Business websites service page with the headline “A business website that helps customers take the next step” and a Discuss your project button" }
    ] },
    { id: "design-it-yourself", title: "Design it yourself", steps: [
      { image: "07-offer", ratio: "16 / 10", heading: "Design it yourself. We build it for real.",
        body: "Four steps: pick a template, drag in blocks, make it yours, and send it over for a reply with questions, a scope and an estimate. No account needed, and the draft stays in the visitor’s browser until they send it.",
        alt: "A section titled “Design it yourself. We build it for real” with four numbered steps and template shortcuts for business, restaurant, portfolio, product and shop" },
      { image: "08-builder", ratio: "16 / 10", heading: "Start from a real design.",
        body: "The builder opens on “Choose a starting point,” a library of designer templates such as an advisory firm site and an executive dashboard, with the block and style panels waiting behind it.",
        alt: "The Veloce builder with a “Choose a starting point” dialog showing designer templates for an advisory firm and an executive dashboard" }
    ] },
    { id: "how-it-works", title: "How it works", steps: [
      { image: "06-approach", ratio: "16 / 10", heading: "Try the process, not just read about it.",
        body: "“Then we build it with you” moves through think it, build it, make it work. An example workflow lets visitors pick a problem, like scattered customer bookings, and decide what the first version should do.",
        alt: "The approach section with Think it, Build it and Make it work tabs, and an interactive “Try the process” panel for a customer bookings example" },
      { image: "09-get-in-touch", ratio: "16 / 10", heading: "Your idea shouldn’t stay an idea.",
        body: "The page closes with one invitation: describe what you want to build, improve or solve, then request a meeting or a consultation.",
        alt: "A dark contact panel reading “Your idea shouldn’t stay an idea” with buttons to request a meeting or a consultation" },
      { image: "10-about", ratio: "16 / 10", heading: "Philippine roots. Practical thinking.",
        body: "The About page introduces independent development based in the Philippines and working remotely, building websites and systems around each business.",
        alt: "The Veloce About page headlined “Philippine roots. Practical thinking.” beside a photo of limestone cliffs in El Nido, Palawan" }
    ] }
  ].freeze

  # Expands the three database-managed chapters. The short database text stays as the lead
  # sentence (editable in the admin); these notes are checked against the Veloce-Dev repository.
  VELOCE_CASE = {
    "the-problem" => {
      intro: "A business that wants a custom website usually has to commit before it can picture the result, and the people who recommend that business have no clean way to introduce it. Three gaps kept showing up.",
      items: [
        ["Services were hard to browse", "A flat list of services doesn’t tell a visitor which one fits their business. They needed a way to explore by need, such as reaching customers, running the day-to-day, or improving what already exists."],
        ["Nobody could picture the finished site", "Without examples, “custom website” stays abstract. A visitor should be able to see finished sample sites, and even sketch their own, before deciding to talk."],
        ["Introductions couldn’t be traced", "The referral designs I started from shared a message with no link, a “Copy link” button that copied the company homepage, and an offer claimed through a self-declared checkbox. Nothing tied a new inquiry back to the person who made the introduction."]
      ]
    },
    "my-contribution" => {
      intro: "Veloce is a personal project and I built it end to end: the interface, the data model, the server logic, the tests, and the documentation behind the decisions.",
      items: [
        ["The sales experience", "The landing page, the sample-site carousel, and the service book that groups services by need, with “ask about this” on every page."],
        ["Referral pages and links", "Personalised referral pages, plus a prospect link that carries a private token so the offer and the introducing person show up when the link is opened."],
        ["A lead and introduction pipeline", "Inquiry and introduction forms feed a PostgreSQL pipeline. Leads move through New, Contacted, Consultation scheduled, Proposal in progress, then Converted or Not proceeding."],
        ["A website builder", "A browser-based builder with starter templates, movable blocks, theme controls, and an importer that turns exported HTML designs into editable templates."],
        ["Meeting booking and analytics", "A meeting request flow with optional Cal.com scheduling, and consent-first analytics. Both ship switched off until real accounts and disclosures are configured, so status here is “in development”."],
        ["Tests and written decisions", "Vitest unit and integration tests, Playwright end-to-end tests at mobile, tablet and desktop sizes with accessibility checks, and decision records for the choices that weren’t obvious."]
      ]
    },
    "under-the-hood" => {
      intro: "Next.js App Router and React 19 power the interface, written in strict TypeScript with Tailwind CSS 4 and Radix UI. Prisma 7 and PostgreSQL hold the data, and the builder runs on the Puck editor.",
      items: [
        ["Clear layers", "Components call server actions, actions call services, and services talk to Prisma. Components never import the database client, and services never import React."],
        ["One schema for both sides", "Each form has a single Zod schema used by the browser for instant feedback and again on the server, so the rules can’t drift apart."],
        ["Referral attribution on the server", "The link carries a long random token, never the database id. The server looks the campaign up and records the attribution itself. A bad or expired token degrades quietly instead of showing an error, and an expired offer is simply not shown."],
        ["Safe to retry", "Each form submission carries an idempotency key, so a double-click or a network retry can’t create a second lead. Notifications are logged before sending with a unique key, so the same email isn’t sent twice."],
        ["Abuse and input handling", "A honeypot field, Postgres-backed rate limiting that works across server instances, and strict security headers including a content security policy. Builder HTML is sanitized in the browser and cleaned again on the server."],
        ["Privacy by default", "Analytics are off unless enabled, load only after the visitor consents, and drop query strings and referral tokens from recorded paths."]
      ]
    }
  }.freeze

  def veloce_story
    VELOCE_STORY
  end

  def veloce_case(id)
    VELOCE_CASE[id]
  end
end
