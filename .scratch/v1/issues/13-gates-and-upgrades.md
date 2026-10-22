# 13: Gates and upgrades

**What to build:** Day's five Gates (three Warrior Gates, two Speed Gates) start neutral and usable by both Teams. A Queen claims a Gate by touching it, turning it her Team's colour so only her Workers can use it, until the other Queen touches it. A Worker carrying a Berry who stands still at a usable Gate transforms: 50 ticks holding the Berry overhead (can be killed or Bumped out), then 50 ticks locked in (invisible, invulnerable), then emerges upgraded with blinking invulnerability that ends early if they pick up a Berry. A Speed Gate makes a Speed Worker (1.35× horizontal speed and rise rate); a Warrior Gate makes a Warrior, or a Speed Warrior from a Speed Worker. Upgrades are lost on death.

**Blocked by:** 08, 12

**Status:** ready-for-agent

- [ ] Test: a Queen touching a neutral or enemy Gate claims it; Workers can't use an enemy-owned Gate
- [ ] Test: a Worker with a Berry becomes a Warrior after 100 ticks at an owned Warrior Gate, and the Berry is consumed
- [ ] Test: a kill or Bump during the first 50 ticks interrupts the transform; the Worker can't be harmed during the last 50
- [ ] Test: a Worker without a Berry standing at a Gate stays a Worker
- [ ] Test: a Speed Worker re-entering a Speed Gate stays as they are and keeps the Berry
- [ ] Test: a Speed Worker at a Warrior Gate becomes a Speed Warrior; dying loses all upgrades
- [ ] Test: emerge invulnerability ends when the character picks up a Berry
- [ ] Speed raises the ceiling stick/ricochet threshold (ticket 06's hook)
- [ ] Gate colour shows ownership on screen; Gate claim and transform events are emitted
