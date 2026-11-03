# Agent-Based Modeling in Economics
## How Does a New Technology Spread? — An Agent-Based Simulation of UPI / Digital-Payment Adoption in NetLogo

| | |
|---|---|
| **College** | Faculty of Technology, University of Delhi |
| **Course** | B.Tech Computer Science Engineering |
| **Year / Semester** | 2nd Year, Semester 3 |
| **Project Type** | Agent-Based **Simulation** (a NetLogo model — not a website or an app) |
| **Tool** | [NetLogo](https://ccl.northwestern.edu/netlogo/) (desktop) / NetLogo Web |
| **Reference Book** | Delli Gatti, Fagiolo, Gallegati, Richiardi & Russo (eds.), *Agent-Based Models in Economics: A Toolkit*, Cambridge University Press, 2018 |

---

## 1. What is this project? (In one paragraph)

This project is a **computer simulation of an economy made of individual people (agents)** who decide, one by one, whether to start using a new product — here, **UPI / digital payments**. Each person is influenced by two things: **advertising** (an outside push) and **their friends and neighbours who already use it** (word-of-mouth). We don't write an equation for the whole market. We only program the rules for *one* person, put 1,000 of them on a social network, press **Go**, and watch the market-wide adoption curve **emerge** from their interactions. The model is the agent-based version of the **Bass diffusion model**, which our reference book works through in Chapter 7 (Section 7.3.4).

---

## 2. Problem Statement

> **Why do new products and technologies (like UPI, smartphones, electric vehicles) spread slowly at first, then suddenly take off, and finally saturate? And how do advertising, word-of-mouth, and the structure of people's social connections change how fast this happens?**

Traditional (mainstream) economics answers this with an **aggregate equation**: the classical Bass model (1969). It assumes that:

1. **Everyone is identical** (a "representative agent").
2. **Everyone is connected to everyone**, so every person is influenced by the adoption rate of the *entire* population.

The reference book explains (Ch. 1, 2 and 7) why this is unrealistic. Real people are **heterogeneous**, they have **limited information** and **bounded rationality**, and they are influenced mostly by their **local contacts**, not the whole country. An aggregate equation cannot show:

- how adoption spreads **through a social network**, cluster by cluster;
- what happens when some people are **more innovative** than others;
- which **policy** works better: more advertising, referral cashback, or targeting influencers.

---

## 3. Our Solution

We build an **Agent-Based Model (ABM)** in NetLogo where:

- **Agents** = individual people (potential users of UPI).
- **Environment** = a **social network** that links agents to their friends (small-world, random, or fully connected).
- **State of each agent** = `adopted?` (0 = not using UPI, 1 = using UPI).
- **Behavioural rule** (from the book, Eq. 7.9): at every time step, a non-adopter *i* adopts with probability

$$
\Pr_{i,t}(\text{adopt}) = p + q \cdot A_{i,t}
$$

| Symbol | Meaning | Economic interpretation |
|---|---|---|
| `p` | Innovation coefficient | External influence: **advertising**, media, government campaigns |
| `q` | Imitation coefficient | Internal influence: **word-of-mouth**, peer pressure, social learning |
| `A(i,t)` | Share of agent *i*'s friends who have already adopted | **Local interaction** (replaces the global term F(t) of the classical model) |
| `n` | Average number of links per agent | How socially connected people are |

Nobody in the model "solves" an optimisation problem. Agents follow a **simple heuristic**: "I may try it because I saw an ad, and I'm more likely to try it if my friends use it." This is the **bounded rationality / social learning** view of behaviour from Ch. 5 of the book.

The **S-shaped adoption curve** of the market is not programmed anywhere. It **emerges** from these micro-level interactions. That emergence is the central idea of agent-based economics.

### What we add beyond the book's example
1. **Network choice:** compare *fully connected* (= classical Bass), *random*, and *small-world* networks.
2. **Heterogeneous agents:** each agent can get its own innovativeness `p_i` (drawn around the average `p`), so people are not identical.
3. **Policy experiments:**
   - 📢 **Advertising campaign:** raise `p`
   - 🤝 **Referral cashback:** raise `q`
   - ⭐ **Seeding influencers:** start with a few early adopters placed on the *most-connected* agents vs. *random* agents

---

## 4. What the Simulation Looks Like (NetLogo Interface)

**Controls (sliders / choosers)**

| Widget | Default | Purpose |
|---|---|---|
| `num-agents` | 1000 | Population size |
| `p` (innovation) | 0.03 | Advertising effect |
| `q` (imitation) | 0.40 | Word-of-mouth effect |
| `avg-links` (n) | 5 | Average friends per agent |
| `rewire-prob` | 0.1 | Small-world randomness |
| `network-type` | small-world | small-world / random / fully-connected |
| `heterogeneous?` | off | Give each agent a different `p_i` |
| `seed-strategy` | none | none / random / influencers |
| **Setup**, **Go** buttons | | Build the network, run the simulation |

*Default values are the book's reference configuration (p = 0.03, q = 0.4, n = 5, 1,000 agents).*

**Outputs**

- 🟢 / ⚪ **Network view:** agents turn from grey (non-adopter) to green (adopter) as UPI spreads.
- 📈 **Plot 1, Cumulative adoption:** the S-curve (% of population using UPI over time).
- 📊 **Plot 2, New adopters per tick:** the bell-shaped curve of adoption speed.
- 🔢 **Monitors:** % adopted, current tick, and the **tick at which 50% of people have adopted** (our key output, same as in the book).

---

## 5. Model Logic (Pseudocode)

```
SETUP
  create num-agents people, all with adopted? = false
  build the social network (small-world / random / fully-connected) with avg-links = n
  if heterogeneous?  → give each person p_i drawn around p
  if seed-strategy   → mark a few seed agents as adopters

GO  (repeat every tick, until everyone has adopted)
  ask every non-adopter i:
      A_i  ← (number of adopted friends) / (number of friends)
      prob ← p_i + q × A_i
      if random-float 1 < prob  → set adopted? true, turn green
  update plots and monitors
  if 50% adopted for the first time → record tick as time-to-50%
```

This is exactly the **recursive structure of an AB model** described in Ch. 3:
`x(i, t+1) = f( x(i,t), x(−i,t), θ, ξ(i,t) )`: each agent's next state depends on its own state, its neighbours' states, the parameters θ = (p, q, n), and randomness ξ.

---

## 6. Experiments We Will Run

Using NetLogo's **BehaviorSpace** tool, following the **sensitivity analysis** method of Ch. 7:

| # | Experiment | What we vary | What we measure |
|---|---|---|---|
| E1 | Baseline | p = 0.03, q = 0.4, n = 5 | S-curve, time to 50% adoption |
| E2 | Advertising effect | `p` from 0 to 0.2 | Time to 50% |
| E3 | Word-of-mouth effect | `q` from 0 to 1 | Time to 50% |
| E4 | Connectivity effect | `n` from 1 to 30 | Time to 50% |
| E5 | Network structure | fully-connected vs. random vs. small-world | Shape of S-curve |
| E6 | Policy comparison | Ads vs. cashback vs. influencer seeding | Time to 50% |

Each configuration is repeated over **multiple runs (e.g., 50)** and averaged, because the model is stochastic. This is the method the book uses.

**Expected results (based on the book's findings, Ch. 7.3.4)**
- `p` (advertising) has the **strongest** effect on speed, especially when `p` is small.
- Raising `q` helps, but beyond a point the curves become very similar.
- Beyond about **6 links per agent**, adding more connections barely changes the result.
- Every run eventually reaches 100% adoption (when p > 0). The interesting part is **how fast** the market gets there.

---

## 7. Project Roadmap

```
 Phase 1        Phase 2         Phase 3          Phase 4           Phase 5          Phase 6
 Study    ──▶   Design    ──▶   Build in   ──▶   Experiment  ──▶   Validate   ──▶   Present
 the book       the model       NetLogo          (BehaviorSpace)   & analyse        & report
   ✅              ✅              🔄                 ⏳                ⏳               ⏳
```

### ✅ Phase 1: Literature Study (reference book)
- [x] Ch. 1–2: what ABMs are and why economics needs them (complexity, heterogeneity, emergence; Schelling's segregation model in NetLogo)
- [x] Ch. 3: ABMs as recursive systems; how a model is structured and simulated
- [x] Ch. 4–5: bounded rationality, heuristics, social learning (vs. full rationality)
- [x] Ch. 6: modeling interaction; lattices and networks (random, small-world)
- [x] Ch. 7: the agent-based experiment; **Bass diffusion model with local interaction**; sensitivity analysis
- [x] Ch. 8–9: empirical validation and estimation (overview)

### ✅ Phase 2: Model Design
- [x] Define problem statement and economic question
- [x] Choose agents, environment, state variables, and behavioural rule (`p + q·A`)
- [x] Fix parameters and default values (from the book)
- [x] Decide outputs: S-curve, new adopters per tick, time to 50% adoption

### 🔄 Phase 3: Implementation in NetLogo *(current phase)*
- [ ] Build the interface: sliders, choosers, buttons, plots, monitors
- [ ] Write `setup`: create agents and build the network
- [ ] Write `go`: the adoption rule, colour change, plot updates
- [ ] Add heterogeneous agents and seeding strategies
- [ ] Test and debug (check that p = 0 and no seeds means no adoption, etc.)

### ⏳ Phase 4: Experiments
- [ ] Set up BehaviorSpace experiments E1–E6
- [ ] Run each configuration multiple times and export results to CSV
- [ ] Plot the average curves

### ⏳ Phase 5: Validation & Analysis
- [ ] **Qualitative validation** (Ch. 8): does the model reproduce the S-shaped adoption pattern seen for real products?
- [ ] Compare our results with the book's sensitivity-analysis findings
- [ ] Interpret the policy experiments: which policy speeds up digital-payment adoption the most?

### ⏳ Phase 6: Presentation & Report
- [ ] Final presentation with live demo of the NetLogo model
- [ ] Short report: problem, model, experiments, results, conclusion
- [ ] Upload final `.nlogo` file, results, and screenshots to this repository

---

## 8. How This Project Maps to the Reference Book

| Book chapter | Concept | Where it appears in our project |
|---|---|---|
| Ch. 1–2 | Economy as a complex system of heterogeneous interacting agents; emergence | Market-level S-curve emerges from individual decisions |
| Ch. 2.5 | Schelling's segregation model implemented in NetLogo | Shows NetLogo is a standard ABM tool; same "simple rules → complex outcome" idea |
| Ch. 3 | ABMs as recursive systems `x(t+1) = f(x(t), …)` | Our `go` procedure updates every agent's state each tick |
| Ch. 4–5 | Bounded rationality, heuristics, social learning | Agents imitate friends instead of optimising |
| Ch. 6 | Local interaction and networks (random, small-world) | Social network connecting the agents |
| Ch. 7 | Bass diffusion with local interaction; sensitivity analysis | Core model and experiments E1–E6 |
| Ch. 8 | Empirical validation (qualitative output validation) | Checking the S-curve against real adoption patterns |

---

## 9. Why an Agent-Based Model (and not just an equation)?

| Classical Bass model (equation) | Our agent-based model |
|---|---|
| One equation for the whole market | Rules for each individual |
| Everyone identical | Agents can be heterogeneous |
| Everyone influenced by the whole population | Agents influenced by their own friends (network) |
| Cannot test "target the influencers" | Can test seeding strategies directly |
| Result is calculated | Result **emerges** and can be watched live |

---

## 10. Repository Structure (planned)

```
agent-based-modeling-in-economics/
├── README.md                 ← project overview (this file)
├── model/
│   └── upi-adoption.nlogo    ← NetLogo simulation (Phase 3)
├── experiments/
│   └── results/*.csv         ← BehaviorSpace outputs (Phase 4)
├── screenshots/              ← interface & result plots
└── presentation/             ← slides (Phase 6)
```

---

## 11. How to Run (once the model is uploaded)

1. Install **NetLogo** (free) from https://ccl.northwestern.edu/netlogo/, or open **NetLogo Web** in a browser.
2. Open `model/upi-adoption.nlogo`.
3. Set the sliders (or keep the defaults), click **Setup**, then **Go**.
4. Watch agents turn green and the S-curve form in the plot.

---

## 12. References

1. Delli Gatti, D., Fagiolo, G., Gallegati, M., Richiardi, M., & Russo, A. (Eds.) (2018). *Agent-Based Models in Economics: A Toolkit*. Cambridge University Press. (Especially Ch. 2, 3, 5, 6, 7.3.4 and 8.)
2. Bass, F. M. (1969). A New Product Growth for Model Consumer Durables. *Management Science*, 15(5), 215–227.
3. Mahajan, V., Muller, E., & Bass, F. M. (1995). Diffusion of New Products: Empirical Generalizations and Managerial Uses. *Marketing Science*, 14(3).
4. Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of "small-world" networks. *Nature*, 393, 440–442.
5. Wilensky, U. (1999). *NetLogo*. Center for Connected Learning and Computer-Based Modeling, Northwestern University.
