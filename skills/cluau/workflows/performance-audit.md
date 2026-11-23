# Workflow: performance audit

1. **Measure first** (performance.md §1): which device, how many players, FPS/ping/memory symptoms. MicroProfiler
   for spikes, Developer Console (Memory: LuaHeap/Instances; Network KB/s; Scripts activity), Script Profiler,
   Scene Analysis (triangles/memory). Real low-end Android if mobile is affected.
2. **Compare to budgets:** custom traffic ≤ 20–30 KB/s; ~9 B per remote fire; UnreliableRemoteEvent ≤ 1000 B;
   40–60 moving assemblies; > 30 moving Humanoids → client-rendered entities; ~100 draw calls / 150k tris
   comfortable, 1,000 / 1M ceiling.
3. **Rank the top 3 costs** by measured impact. Ignore micro-optimizations that aren't on the profile.
4. **Fix with known patterns:** batch + quantize remotes, one loop for many entities, pooling, CollectionService
   registries, instancing/SLIM/RenderFidelity, CollisionFidelity, cosmetic work on clients, Parallel Luau only for
   real parallel compute.
5. **Leaks:** 50 join/leave cycles while watching LuaHeap; Trove per lifetime (CX-13).
6. **Re-measure** and report before/after numbers. Don't claim a speedup you didn't measure.
