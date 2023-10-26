// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module color_object::example {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct ColorObject has key, store {
        id: UID,
        red: u8,
        green: u8,
        blue: u8,
    }

    // === Functions covered in Chapter 1 ===

    public fun new(
        red: u8,
        green: u8,
        blue: u8,
        ctx: &mut TxContext,
    ): ColorObject {
        ColorObject { id: object::new(ctx), red, green, blue }
    }

    public fun get_color(self: &ColorObject): (u8, u8, u8) {
        (self.red, self.green, self.blue)
    }

    // === Functions covered in Chapter 2 ===

    /// Copies the values of `from` into `into`.
    public fun copy_into(from: &ColorObject, into: &mut ColorObject) {
        into.red = from.red;
        into.green = from.green;
        into.blue = from.blue;
    }

    public fun delete(object: ColorObject) {
        let ColorObject { id, red: _, green: _, blue: _ } = object;
        object::delete(id);
    }

    // === Functions covered in Chapter 3 ===

    public fun update(
        object: &mut ColorObject,
        red: u8,
        green: u8,
        blue: u8,
    ) {
        object.red = red;
        object.green = green;
        object.blue = blue;
    }

    // === Tests ===
    use sui::test_scenario as ts;

    // === Tests covered in Chapter 1 ===

    #[test]
    fun test_create() {
        let ts = ts::begin(@0x0);
        let alice = @0xA;
        let bob = @0xB;

        // Create a ColorObject and transfer it to its owner.
        {
            ts::next_tx(&mut ts, alice);
            let color = new(255, 0, 255, ts::ctx(&mut ts));
            transfer::public_transfer(color, alice);
        };

        // Check that @not_owner does not own the just-created ColorObject.
        {
            ts::next_tx(&mut ts, bob);
            assert!(!ts::has_most_recent_for_sender<ColorObject>(&mut ts), 0);
        };

        // Check that owner indeed owns the just-created ColorObject.
        // Also checks the value fields of the object.
        {
            ts::next_tx(&mut ts, alice);
            let object: ColorObject = ts::take_from_sender(&mut ts);
            let (red, green, blue) = get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            ts::return_to_sender(&mut ts, object);
        };

        ts::end(ts);
    }

    // === Tests covered in Chapter 2 ===

    #[test]
    fun test_copy_into() {
        let ts = ts::begin(@0x0);
        let owner = @0xA;

        // Create two ColorObjects owned by `owner`, and obtain their IDs.
        let (id1, id2) = {
            ts::next_tx(&mut ts, owner);
            let ctx = ts::ctx(&mut ts);

            let c = new(255, 255, 255, ctx);
            transfer::public_transfer(c, owner);
            let id1 = object::id_from_address(
                tx_context::last_created_object_id(ctx),
            );

            let c = new(0, 0, 0, ctx);
            transfer::public_transfer(c, owner);
            let id2 = object::id_from_address(
                tx_context::last_created_object_id(ctx),
            );

            (id1, id2)
        };

        {
            ts::next_tx(&mut ts, owner);
            let obj1: ColorObject = ts::take_from_sender_by_id(&mut ts, id1);
            let obj2: ColorObject = ts::take_from_sender_by_id(&mut ts, id2);
            let (red, green, blue) = get_color(&obj1);
            assert!(red == 255 && green == 255 && blue == 255, 0);

            copy_into(&obj2, &mut obj1);
            ts::return_to_sender(&mut ts, obj1);
            ts::return_to_sender(&mut ts, obj2);
        };

        {
            ts::next_tx(&mut ts, owner);
            let obj1: ColorObject = ts::take_from_sender_by_id(&mut ts, id1);
            let (red, green, blue) = get_color(&obj1);
            assert!(red == 0 && green == 0 && blue == 0, 0);
            ts::return_to_sender(&mut ts, obj1);
        };

        ts::end(ts);
    }

    #[test]
    fun test_delete() {
        let ts = ts::begin(@0x0);
        let owner = @0xA;

        // Create a ColorObject and transfer it to owner.
        {
            ts::next_tx(&mut ts, owner);
            let c = new(255, 0, 255, ts::ctx(&mut ts));
            transfer::public_transfer(c, owner);
        };

        // Delete the ColorObject we just created.
        {
            ts::next_tx(&mut ts, owner);
            let object: ColorObject = ts::take_from_sender(&mut ts);
            delete(object);
        };

        // Verify that the object was indeed deleted.
        {
            ts::next_tx(&mut ts, owner);
            assert!(!ts::has_most_recent_for_sender<ColorObject>(&mut ts), 0);
        };

        ts::end(ts);
    }

    #[test]
    fun test_transfer() {
        let ts = ts::begin(@0x0);
        let sender = @0xA;
        let recipient = @0xB;

        // Create a ColorObject and transfer it to sender.
        {
            ts::next_tx(&mut ts, sender);
            let c = new(255, 0, 255, ts::ctx(&mut ts));
            transfer::public_transfer(c, @0xA);
        };

        // Transfer the object to recipient.
        {
            ts::next_tx(&mut ts, sender);
            let object: ColorObject = ts::take_from_sender(&mut ts);
            transfer::public_transfer(object, recipient);
        };

        // Check that sender no longer owns the object.
        {
            ts::next_tx(&mut ts, sender);
            assert!(!ts::has_most_recent_for_sender<ColorObject>(&mut ts), 0);
        };

        // Check that recipient now owns the object.
        {
            ts::next_tx(&mut ts, recipient);
            assert!(ts::has_most_recent_for_sender<ColorObject>(&mut ts), 0);
        };

        ts::end(ts);
    }

    // === Tests covered in Chapter 3 ===

    #[test]
    fun test_immutable() {
        let ts = ts::begin(@0x0);
        let alice = @0xA;
        let bob = @0xB;

        {
            ts::next_tx(&mut ts, alice);
            let c = new(255, 0, 255, ts::ctx(&mut ts));
            transfer::public_freeze_object(c);
        };

        // take_owned does not work for immutable objects.
        {
            ts::next_tx(&mut ts, alice);
            assert!(!ts::has_most_recent_for_sender<ColorObject>(&mut ts), 0);
        };

        // Any sender can work.
        {
            ts::next_tx(&mut ts, bob);
            let object: ColorObject = ts::take_immutable(&mut ts);
            let (red, green, blue) = get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            ts::return_immutable(object);
        };

        ts::end(ts);
    }
}