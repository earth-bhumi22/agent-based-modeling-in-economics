# Agent-Based Modeling in Economics
## How Does a New Technology Spread? — An Agent-Based Simulation of UPI / Digital-Payment Adoption in NetLogo

| | |
|---|---|
| **College** | Faculty of Technology, University of Delhi |
| **Course** | B.Tech Computer Science Engineering |
| **Year / Semester** | 2nd Year, Semester 3 |
| **Project Type** | Agent-Based **Simulation** (a NetLogo model — not a website or an app) |
| **Tool** | [NetLogo](https://ccl.northwestern.edu/netlogo/) 6.4 (desktop) |
| **Status** | ✅ Working simulation · ✅ Experiments run · ⏳ Validation & report |
| **Reference Book** | Delli Gatti, Fagiolo, Gallegati, Richiardi & Russo (eds.), *Agent-Based Models in Economics: A Toolkit*, Cambridge University Press, 2018 |

![UPI Adoption Simulator: adoption taking off on a small-world network](screenshots/02-takeoff-small-world.png)

---

## 1. What is this project? (In one paragraph)

This project is a **computer simulation of an economy made of individual people (agents)** who decide, one by one, whether to start using a new product — here, **UPI / digital payments**. Each person is influenced by two things: **advertising** (an outside push) and **their friends who already use it** (word-of-mouth). We don't write an equation for the whole market. We only program the rules for *one* person, put 1,000 of them on a social network, press **Go**, and watch the market-wide adoption curve **emerge** from their interactions. The model is the agent-based version of the **Bass diffusion model**, which our reference book works through in Chapter 7 (Section 7.3.4).

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
- **Environment** = a **social network** linking agents to their friends.
- **State of each agent** = `adopted?` (not using / using UPI) and `adopted-via` (ads, friends, or seed).
- **Behavioural rule** (from the book, Eq. 7.9): every week, a non-user *i* adopts with probability

$$
\Pr_{i,t}(\text{adopt}) = p + q \cdot A_{i,t}
$$

| Symbol | Meaning | Economic interpretation |
|---|---|---|
| `p` | Innovation coefficient | External influence: **advertising**, media, government campaigns |
| `q` | Imitation coefficient | Internal influence: **word-of-mouth**, peer pressure, social learning |
| `A(i,t)` | Share of agent *i*'s friends who already use UPI | **Local interaction** (replaces the global term F(t) of the classical model) |
| `n` | Average number of friends per agent | How socially connected people are |

Nobody in the model "solves" an optimisation problem. Agents follow a **simple heuristic**: "I may try it because I saw an ad, and I'm more likely to try it if my friends use it." This is the **bounded rationality / social learning** view of behaviour from Ch. 5 of the book.

The **S-shaped adoption curve** of the market is not programmed anywhere. It **emerges** from these micro-level interactions. That emergence is the central idea of agent-based economics.

### What we add beyond the book's example
1. **Four network types:** small-world (the book's case), random, scale-free (with big "influencers"), and fully mixed (= the classical Bass equation).
2. **Live comparison with the classical equation:** the S-curve plot draws the ABM and the aggregate Bass equation side by side.
3. **Innovators vs. imitators:** every adopter is coloured by *why* they adopted (ads = blue, friends = green).
4. **Heterogeneous agents:** each agent can get its own `p_i` and `q_i`.
5. **Policy experiments:** 📢 advertising campaign (p × 3), 🤝 referral cashback (q × 2), both together, and ⭐ seeding the top influencers vs. random people.

---

## 4. The Simulation

### Interface

| Area | What it contains |
|---|---|
| **Left panel** | 1. Population & network (size, network type, avg friends, rewiring, show links, heterogeneity) · 2. Behaviour (`p`, `q`) · 3. Policy experiments (policy, seed strategy, number of seeds) · **Setup / Go / Step** buttons · colour legend |
| **Centre** | Live network view: each dot is a person. Grey = not using UPI · **blue** = adopted because of ads · **green** = adopted because of friends · **gold** = seeded influencer · bright flash = adopted this week · bigger dot = more friends |
| **Below the view** | 12 live monitors: % on UPI, users, week, **week when 50% adopted**, peak week, avg links, % of users via ads / friends / seeds, new users this week, classical Bass % |
| **Right panel** | 4 plots: (1) **S-curve**, ABM vs. classical Bass equation · (2) **new users per week**, split into innovators and imitators · (3) **degree distribution** of the network · (4) **adoption rate** of remaining non-users vs. the theoretical `p + q·F(t)` (book, Eq. 7.7) |

*Default values are the book's reference configuration: p = 0.03, q = 0.4, n = 5, 1,000 agents.*

### Screenshots (taken from the real NetLogo model)

| Week 0: Setup | Week 7: Take-off | Week 22: Saturation |
|---|---|---|
| ![setup](screenshots/01-setup-small-world.png) | ![takeoff](screenshots/02-takeoff-small-world.png) | ![saturation](screenshots/03-saturation-small-world.png) |

| Scale-free network seeded with top influencers (gold, centre) | Policy: advertising campaign (p × 3) |
|---|---|
| ![influencers](screenshots/04-influencers-scale-free.png) | ![policy](screenshots/05-policy-advertising.png) |

---

## 5. Model Logic

```
SETUP
  create num-agents people (not using UPI)
  build the social network: small-world / random / scale-free / fully mixed
  apply policy               → effective p and q
  if heterogeneous?          → each person gets own p_i, q_i
  if seed-strategy           → a few random people or top influencers start as users

GO  (every week, until everyone uses UPI)
  for every non-user i (decisions based on the state at the START of the week):
      A_i ← share of i's friends using UPI      (whole population if fully mixed)
      r   ← random number in [0, 1)
      if r < p_i              → adopts "because of ads"     (innovator, blue)
      else if r < p_i + q_i·A_i → adopts "because of friends" (imitator, green)
  apply all decisions together (synchronous update)
  update the classical Bass equation  F ← F + (1 − F)(p + qF)  for comparison
  update plots and monitors; record the week when 50% have adopted
```

This is the **recursive structure of an AB model** described in Ch. 3:
`x(i, t+1) = f( x(i,t), x(−i,t), θ, ξ(i,t) )`: each agent's next state depends on its own state, its neighbours' states, the parameters θ = (p, q, n), and randomness ξ.

---

## 6. Experiments & Results

All experiments are built into the model (**Tools → BehaviorSpace**, experiments E1–E7). Each configuration is repeated many times and averaged, because the model is stochastic. This follows the sensitivity-analysis method of Ch. 7. Raw outputs are in [`experiments/results/`](experiments/results).

**Key output:** the week in which **50% of the population** uses UPI (the book's main output statistic). Lower = faster adoption.

### E6: Which policy works best? *(small-world, 30 runs each)*

| Policy | Weeks to 50% adoption | Weeks until everyone adopts |
|---|---|---|
| None (baseline) | **8.3** | 25.9 |
| 📢 Advertising campaign (p × 3) | **4.9** | 17.9 |
| 🤝 Referral cashback (q × 2) | **6.1** | 15.1 |
| 📢 + 🤝 Both | **4.0** | 10.5 |

➡️ Advertising has the bigger effect on reaching the **first half** of the market. Cashback mainly speeds up the **last stragglers** (shorter tail), because word-of-mouth gets stronger as more friends adopt.

### E7: Who should we target first? *(scale-free network, very low advertising p = 0.005, 30 runs each)*

| Seed strategy | Weeks to 50% adoption |
|---|---|
| No seeding | **15.2** |
| 10 random people | **13.2** |
| ⭐ 10 top influencers | **7.5** |

➡️ Giving UPI to the **10 most-connected people** makes the market reach 50% **twice as fast**. Seeding 10 random people barely helps. This is a policy insight an aggregate equation cannot produce, because it has no network.

### E5: Does the network structure matter? *(30 runs each)*

| Network | Weeks to 50% | Weeks until everyone adopts |
|---|---|---|
| Fully mixed (classical Bass) | 7.5 | 21.4 |
| Scale-free (influencers) | 8.0 | 23.0 |
| Small-world | 8.2 | 30.6 |
| Random | 8.2 | 91.2 |

➡️ The networks reach 50% at similar speeds, but the **tail** is very different. In a random network some people have **no friends at all**, so they can only be reached by advertising and adopt very late. Local interaction slows full adoption compared with the classical "everyone sees everyone" assumption.

### Comparison with the book (Ch. 7.3.4)
- ✅ The model reproduces the **S-shaped adoption curve** (qualitative validation, Ch. 8).
- ✅ **p (advertising)** has the strongest effect on speed, as the book finds.
- ✅ Higher **q** speeds adoption but with diminishing effect.

---

## 7. Project Roadmap

```
 Phase 1        Phase 2         Phase 3          Phase 4           Phase 5          Phase 6
 Study    ──▶   Design    ──▶   Build in   ──▶   Experiment  ──▶   Validate   ──▶   Present
 the book       the model       NetLogo          (BehaviorSpace)   & analyse        & report
   ✅              ✅              ✅                 🔄                🔄               ⏳
```

### ✅ Phase 1: Literature Study (reference book)
- [x] Ch. 1–2: what ABMs are and why economics needs them (complexity, heterogeneity, emergence; Schelling's segregation model in NetLogo)
- [x] Ch. 3: ABMs as recursive systems; how a model is structured and simulated
- [x] Ch. 4–5: bounded rationality, heuristics, social learning (vs. full rationality)
- [x] Ch. 6: modeling interaction; lattices and networks (random, small-world)
- [x] Ch. 7: the agent-based experiment; **Bass diffusion model with local interaction**; sensitivity analysis
- [x] Ch. 8–9: empirical validation and estimation (overview)

### ✅ Phase 2: Model Design
- [x] Problem statement and economic question
- [x] Agents, environment, state variables, behavioural rule (`p + q·A`)
- [x] Parameters and default values (from the book)
- [x] Outputs: S-curve, new adopters per week, time to 50% adoption

### ✅ Phase 3: Implementation in NetLogo
- [x] Interface: 9 controls, 3 buttons, 12 monitors, 4 plots, colour legend
- [x] `setup`: agents + 4 network types (small-world, random, scale-free, fully mixed)
- [x] `go`: synchronous adoption rule, innovator/imitator colouring, classical Bass benchmark
- [x] Heterogeneous agents, policies and seeding strategies
- [x] Tested: compiles and runs in NetLogo 6.4 (GUI and headless)

### 🔄 Phase 4: Experiments *(current phase)*
- [x] BehaviorSpace experiments E1–E7 built into the model
- [x] E5 (networks), E6 (policies), E7 (seeding) run, results exported to CSV
- [ ] E2 (vary p), E3 (vary q), E1 (baseline over 50 runs), E4 (vary friends 1–30)
- [ ] Charts of the averaged curves for the report

### 🔄 Phase 5: Validation & Analysis
- [x] Qualitative validation: the model reproduces the S-shaped adoption pattern
- [x] Comparison with the book's sensitivity-analysis findings
- [ ] Compare the simulated curve with real UPI adoption trends (input/output validation, Ch. 8)

### ⏳ Phase 6: Presentation & Report
- [ ] Final presentation with live demo
- [ ] Short report: problem, model, experiments, results, conclusion

---

## 8. How This Project Maps to the Reference Book

| Book chapter | Concept | Where it appears in our project |
|---|---|---|
| Ch. 1–2 | Economy as a complex system of heterogeneous interacting agents; emergence | Market-level S-curve emerges from individual decisions |
| Ch. 2.5 | Schelling's segregation model implemented in NetLogo | NetLogo is a standard ABM tool; same "simple rules → complex outcome" idea |
| Ch. 3 | ABMs as recursive systems `x(t+1) = f(x(t), …)` | The `go` procedure updates every agent's state each week |
| Ch. 4–5 | Bounded rationality, heuristics, social learning | Agents imitate friends instead of optimising |
| Ch. 6 | Local interaction and networks (random, small-world) | Four network types connecting the agents |
| Ch. 7 | Bass diffusion with local interaction (Eq. 7.7, 7.9); sensitivity analysis | Core rule, the rate plot, and experiments E1–E7 |
| Ch. 8 | Empirical validation (qualitative output validation) | S-curve check; comparison with the book's findings |

---

## 9. Why an Agent-Based Model (and not just an equation)?

| Classical Bass model (equation) | Our agent-based model |
|---|---|
| One equation for the whole market | Rules for each individual |
| Everyone identical | Agents can be heterogeneous |
| Everyone influenced by the whole population | Agents influenced by their own friends (network) |
| Cannot test "target the influencers" | Can test seeding strategies directly (E7: 2× faster) |
| Result is calculated | Result **emerges** and can be watched live |

---

## 10. Repository Structure

```
agent-based-modeling-in-economics/
├── README.md                          ← project overview (this file)
├── model/
│   └── upi-adoption.nlogo             ← the NetLogo simulation (code, interface, Info tab, BehaviorSpace)
├── experiments/
│   └── results/*.csv                  ← BehaviorSpace outputs
└── screenshots/                       ← interface screenshots from the running model
```

---

## 11. How to Run

1. Install **NetLogo 6.4** (free) from https://ccl.northwestern.edu/netlogo/. Newer NetLogo 7 versions can also open `.nlogo` files.
2. Download this repository (**Code → Download ZIP**) and open `model/upi-adoption.nlogo`.
3. Click **Setup**, then **Go**. Use **Step** to move one week at a time.
4. Try changing **p**, **q**, the **network type**, a **policy**, or **seed strategy → Top influencers**, then click Setup and Go again.
5. To repeat the experiments: **Tools → BehaviorSpace →** choose E1–E7 **→ Run**.
6. The **Info** tab inside the model explains everything in detail.

---

## 12. References

1. Delli Gatti, D., Fagiolo, G., Gallegati, M., Richiardi, M., & Russo, A. (Eds.) (2018). *Agent-Based Models in Economics: A Toolkit*. Cambridge University Press. (Especially Ch. 2, 3, 5, 6, 7.3.4 and 8.)
2. Bass, F. M. (1969). A New Product Growth for Model Consumer Durables. *Management Science*, 15(5), 215–227.
3. Mahajan, V., Muller, E., & Bass, F. M. (1995). Diffusion of New Products: Empirical Generalizations and Managerial Uses. *Marketing Science*, 14(3).
4. Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of "small-world" networks. *Nature*, 393, 440–442.
5. Barabási, A.-L., & Albert, R. (1999). Emergence of scaling in random networks. *Science*, 286, 509–512.
6. Wilensky, U. (1999). *NetLogo*. Center for Connected Learning and Computer-Based Modeling, Northwestern University.
