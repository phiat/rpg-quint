# Quint MBT workflow commands

# List all available recipes
default:
    @just --list

# --- Spec operations ---

# Typecheck all Quint specs
check:
    @for f in specs/*.qnt specs/*/*.qnt; do \
        [ -f "$f" ] || continue; \
        name=$(basename "$f"); \
        printf "%-20s" "$name"; \
        if quint typecheck "$f" 2>&1 | grep -q "error"; then \
            echo "FAIL"; \
            quint typecheck "$f" 2>&1; \
        else \
            echo "ok"; \
        fi; \
    done

# Typecheck a single spec (searches all subdirs)
check-one name:
    @f=$(find specs/ -name "{{name}}.qnt" | head -1); \
    if [ -z "$f" ]; then echo "Not found: {{name}}.qnt"; exit 1; fi; \
    quint typecheck "$f"

# --- Trace generation ---

# Generate MBT traces for all specs
traces:
    @mkdir -p traces
    @for spec in \
        core/rpg:rpg_run \
        core/healing:healing_run \
        core/leveling:leveling_run \
        core/stamina:stamina_run \
        combat/combat:combat_run \
        combat/combat_full:combat_full_run \
        combat/status:status_run \
        combat/cooldown:cooldown_run \
        combat/elemental:elemental_run \
        items/equip:equip_run \
        items/durability:durability_run \
        items/enchantment:enchantment_run \
        items/stacking:stacking_run \
        items/crafting:crafting_run \
        items/capacity_craft:capacity_craft_run \
        items/gated_craft:gated_craft_run \
        items/salvage:salvage_run \
        economy/shop:shop_run \
        economy/dynamic_shop:dynamic_shop_run \
        economy/trade:trade_run \
        economy/loot:loot_run \
        world/world_grid:world_grid_run \
        world/trap:trap_run \
        world/respawn:respawn_run \
        world/companion:companion_run \
        social/party:party_run \
        social/quest:quest_run \
        social/skill_tree:skill_tree_run \
        social/reputation:reputation_run \
        social/summoning:summoning_run \
        economy/auction:auction_run \
        social/faction:faction_run \
        social/dialogue:dialogue_run \
        world/fast_travel:fast_travel_run \
        quint_crawl:quint_crawl_run; \
    do \
        path="${spec%%:*}"; \
        main="${spec##*:}"; \
        name=$(basename "$path"); \
        printf "%-20s" "$name"; \
        if [ "$name" = "quint_crawl" ]; then \
            if quint run --main="$main" --mbt --max-samples=100000 --max-steps=20 --n-traces=5 \
                --out-itf="traces/${name}_trace.itf.json" \
                "specs/${path}.qnt" > /dev/null 2>&1; then \
                echo "ok (100k samples, 5 traces)"; \
            else \
                echo "FAIL"; \
            fi; \
        else \
            if quint run --main="$main" --mbt --max-steps=8 \
                --out-itf="traces/${name}_trace.itf.json" \
                "specs/${path}.qnt" > /dev/null 2>&1; then \
                echo "ok"; \
            else \
                echo "FAIL"; \
            fi; \
        fi; \
    done

# Generate trace for a single spec (searches all subdirs)
trace name main:
    @f=$(find specs/ -name "{{name}}.qnt" | head -1); \
    if [ -z "$f" ]; then echo "Not found: {{name}}.qnt"; exit 1; fi; \
    quint run --main={{main}} --mbt --max-steps=8 \
        --out-itf=traces/{{name}}_trace.itf.json "$f"

# --- Test execution ---

# Run all MBT tests
test:
    @pass=0; fail=0; \
    for d in \
        mbt/core/rpg_mbt mbt/core/healing_mbt mbt/core/leveling_mbt mbt/core/stamina_mbt \
        mbt/combat/combat_mbt mbt/combat/combat_full_mbt mbt/combat/status_mbt mbt/combat/cooldown_mbt mbt/combat/elemental_mbt \
        mbt/items/equip_mbt mbt/items/durability_mbt mbt/items/enchantment_mbt mbt/items/stacking_mbt mbt/items/crafting_mbt mbt/items/capacity_craft_mbt mbt/items/gated_craft_mbt mbt/items/salvage_mbt \
        mbt/economy/shop_mbt mbt/economy/dynamic_shop_mbt mbt/economy/trade_mbt mbt/economy/loot_mbt \
        mbt/world/world_grid_mbt mbt/world/trap_mbt mbt/world/respawn_mbt mbt/world/companion_mbt \
        mbt/social/party_mbt mbt/social/quest_mbt mbt/social/skill_tree_mbt mbt/social/reputation_mbt mbt/social/summoning_mbt \
        mbt/economy/auction_mbt mbt/social/faction_mbt mbt/social/dialogue_mbt mbt/world/fast_travel_mbt \
        quint_crawl_mbt; \
    do \
        name=$(basename "$d"); \
        printf "%-20s" "$name"; \
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

# Run a single MBT test (searches mbt/ and root)
test-one name:
    @d=$(find mbt/ -type d -name "{{name}}_mbt" | head -1); \
    if [ -z "$d" ]; then d="{{name}}_mbt"; fi; \
    if [ ! -d "$d" ]; then echo "Not found: {{name}}_mbt/"; exit 1; fi; \
    odin test "$d/"

# --- Invariant verification ---

# Verify invariants for a spec (100k traces, 20 steps)
verify name main invariant:
    @f=$(find specs/ -name "{{name}}.qnt" | head -1); \
    if [ -z "$f" ]; then echo "Not found: {{name}}.qnt"; exit 1; fi; \
    quint run --main={{main}} --max-steps=20 --max-samples=100000 \
        --invariant="{{invariant}}" "$f"

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
