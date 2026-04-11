package party_mbt

Party :: struct {
    inv_1:      [dynamic]string,
    inv_2:      [dynamic]string,
    inv_3:      [dynamic]string,
    stash:      [dynamic]string,
    member_cap: int,
    stash_cap:  int,
}

// Transfer an item from a member inventory to the shared stash.
// Returns false if the item is not found in the source or the stash is full.
transfer_to_stash :: proc(p: ^Party, src: ^[dynamic]string, itm: string) -> bool {
    if len(p.stash) >= p.stash_cap {
        return false
    }
    for i in 0 ..< len(src) {
        if src[i] == itm {
            ordered_remove(src, i)
            append(&p.stash, itm)
            return true
        }
    }
    return false
}

// Transfer an item from the shared stash to a member inventory.
// Returns false if the item is not found in the stash or the member inventory is full.
transfer_from_stash :: proc(p: ^Party, dst: ^[dynamic]string, itm: string) -> bool {
    if len(dst) >= p.member_cap {
        return false
    }
    for i in 0 ..< len(p.stash) {
        if p.stash[i] == itm {
            ordered_remove(&p.stash, i)
            append(dst, itm)
            return true
        }
    }
    return false
}
