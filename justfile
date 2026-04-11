# Quint MBT workflow commands

# List all available recipes
default:
    @just --list

# --- Spec operations ---

# Typecheck all Quint specs
check:
    @for f in specs/*.qnt; do \
        name=$(basename "$f"); \
        printf "%-20s" "$name"; \
        if quint typecheck "$f" 2>&1 | grep -q "error"; then \
            echo "FAIL"; \
            quint typecheck "$f" 2>&1; \
        else \
            echo "ok"; \
        fi; \
    done

# Typecheck a single spec
check-one name:
    quint typecheck specs/{{name}}.qnt

# --- Trace generation ---

# Generate MBT traces for all specs with a _run module
traces:
    @mkdir -p traces
    @for spec in \
        rpg:rpg_run \
        trade:trade_run \
        equip:equip_run \
        healing:healing_run \
        stacking:stacking_run \
        shop:shop_run \
        combat:combat_run \
        status:status_run \
        crafting:crafting_run \
        party:party_run \
        leveling:leveling_run \
        cooldown:cooldown_run \
        quest:quest_run \
        durability:durability_run \
        loot:loot_run \
        respawn:respawn_run \
        dynamic_shop:dynamic_shop_run \
        combat_full:combat_full_run \
        capacity_craft:capacity_craft_run \
        gated_craft:gated_craft_run \
        stamina:stamina_run \
        skill_tree:skill_tree_run \
        reputation:reputation_run \
        summoning:summoning_run \
        world_grid:world_grid_run \
        quint_crawl:quint_crawl_run; \
    do \
        name="${spec%%:*}"; \
        main="${spec##*:}"; \
        printf "%-20s" "$name"; \
        if quint run --main="$main" --mbt --max-steps=8 \
            --out-itf="traces/${name}_trace.itf.json" \
            "specs/${name}.qnt" > /dev/null 2>&1; then \
            echo "ok"; \
        else \
            echo "FAIL"; \
        fi; \
    done

# Generate trace for a single spec
trace name main:
    quint run --main={{main}} --mbt --max-steps=8 \
        --out-itf=traces/{{name}}_trace.itf.json \
        specs/{{name}}.qnt

# --- Test execution ---

# Run all MBT tests
test:
    @pass=0; fail=0; \
    for d in rpg_mbt trade_mbt equip_mbt healing_mbt stacking_mbt \
             shop_mbt combat_mbt status_mbt crafting_mbt party_mbt leveling_mbt \
             cooldown_mbt quest_mbt durability_mbt loot_mbt respawn_mbt \
             dynamic_shop_mbt combat_full_mbt capacity_craft_mbt gated_craft_mbt \
             stamina_mbt skill_tree_mbt reputation_mbt summoning_mbt world_grid_mbt \
             quint_crawl_mbt; do \
        printf "%-20s" "$d"; \
        if odin test "$d/" 2>&1 | grep -q "was successful"; then \
            echo "pass"; \
            pass=$((pass + 1)); \
        else \
            echo "FAIL"; \
            fail=$((fail + 1)); \
        fi; \
    done; \
    echo ""; \
    echo "$pass passed, $fail failed"

# Run a single MBT test
test-one name:
    odin test {{name}}_mbt/

# --- Invariant verification ---

# Verify invariants for a spec (10k traces, 20 steps)
verify name main invariant:
    quint run --main={{main}} --max-steps=20 --max-samples=10000 \
        --invariant="{{invariant}}" specs/{{name}}.qnt

# --- Game ---

# Build and run the Quint Crawl game
play:
    odin run quint_crawl_game/

# Build the game without running
build-game:
    odin build quint_crawl_game/ -out:quint_crawl_game/quint_crawl

# --- Full pipeline ---

# Run everything: typecheck, generate traces, run tests
all: check traces test

# Regenerate traces and re-test
retest: traces test
