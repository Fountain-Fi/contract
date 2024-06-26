module fountain::fountain_periphery {
   
    use sui::tx_context::{Self, TxContext};
    use sui::clock::Clock;
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::balance;
    use fountain::fountain_core::{Self as core, Fountain, StakeProof, AdminCap};

    #[lint_allow(share_owned)]
    public entry fun create_fountain<S, R>(
        flow_amount: u64,
        flow_interval: u64,
        min_lock_time: u64,
        max_lock_time: u64,
        start_time: u64,
        with_admin_cap: bool,
        ctx: &mut TxContext,
    ) {
        if (with_admin_cap) {
            let (fountain, admin_cap)= core::new_fountain_with_admin_cap<S, R>(
                flow_amount,
                flow_interval,
                min_lock_time,
                max_lock_time,
                start_time,
                ctx,
            );
            transfer::public_share_object(fountain);
            transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        } else {
            let fountain = core::new_fountain<S, R>(
                flow_amount,
                flow_interval,
                min_lock_time,
                max_lock_time,
                start_time,
                ctx,
            );
            transfer::public_share_object(fountain);
        }
    }

    #[lint_allow(share_owned)]
    public entry fun setup_fountain<S, R>(
        clock: &Clock,
        init_supply: Coin<R>,
        flow_amount: u64,
        flow_interval: u64,
        min_lock_time: u64,
        max_lock_time: u64,
        start_time: u64,
        with_admin_cap: bool,
        ctx: &mut TxContext,
    ) {
        if (with_admin_cap) {
            let (mut fountain, admin_cap) = core::new_fountain_with_admin_cap<S, R>(
                flow_amount,
                flow_interval,
                min_lock_time,
                max_lock_time,
                start_time,
                ctx,
            );
            let init_supply = coin::into_balance(init_supply);
            core::supply(clock, &mut fountain, init_supply);
            transfer::public_share_object(fountain);
            transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        } else {
            let mut fountain = core::new_fountain<S, R>(
                flow_amount,
                flow_interval,
                min_lock_time,
                max_lock_time,
                start_time,
                ctx,
            );
            let init_supply = coin::into_balance(init_supply);
            core::supply(clock, &mut fountain, init_supply);
            transfer::public_share_object(fountain);
        }
    }

    public entry fun create_penalty_vault<S, R>(
        admin_cap: &AdminCap,
        fountain: &mut Fountain<S, R>,
        max_penalty_rate: u64,
    ) {
        core::new_penalty_vault(admin_cap, fountain, max_penalty_rate);
    }

    public entry fun supply<S, R>(clock: &Clock, fountain: &mut Fountain<S, R>, resource: Coin<R>) {
        let resource = coin::into_balance(resource);
        core::supply(clock, fountain, resource);
    }

    public entry fun airdrop<S, R>(fountain: &mut Fountain<S, R>, resource: Coin<R>) {
        let resource = coin::into_balance(resource);
        core::airdrop(fountain, resource);
    }

    public entry fun tune<S, R>(fountain: &mut Fountain<S, R>, resource: Coin<R>) {
        let resource = coin::into_balance(resource);
        core::tune(fountain, resource);
    }

    public entry fun stake<S, R>(
        clock: &Clock,
        fountain: &mut Fountain<S, R>,
        input: Coin<S>,
        lock_time: u64,
        ctx: &mut TxContext,
    ) {
        let input = coin::into_balance(input);
        let proof = core::stake(clock, fountain, input, lock_time, ctx);
        transfer::public_transfer(proof, tx_context::sender(ctx));
    }

    public entry fun claim<S, R>(
        clock: &Clock,
        fountain: &mut Fountain<S, R>,
        proof: &mut StakeProof<S, R>,
        ctx: &mut TxContext,
    ) {
        let reward = core::claim(clock, fountain, proof);
        if (balance::value(&reward) > 0) {
            let reward = coin::from_balance(reward, ctx);
            transfer::public_transfer(reward, tx_context::sender(ctx));
        } else {
            balance::destroy_zero(reward);
        };
    }

    public entry fun unstake<S, R>(
        clock: &Clock,
        fountain: &mut Fountain<S, R>,
        proof: StakeProof<S, R>,
        ctx: &mut TxContext,
    ) {
        let (unstake_output, reward) = core::unstake(clock, fountain, proof);
        let unstake_output = coin::from_balance(unstake_output, ctx);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(unstake_output, sender);
        if (balance::value(&reward) > 0) {
            let reward = coin::from_balance(reward, ctx);
            transfer::public_transfer(reward, sender);
        } else {
            balance::destroy_zero(reward);
        }
    }

    public entry fun force_unstake<S, R>(
        clock: &Clock,
        fountain: &mut Fountain<S, R>,
        proof: StakeProof<S, R>,
        ctx: &mut TxContext,
    ) {
        let (unstake_output, reward) = core::force_unstake(clock, fountain, proof);
        let unstake_output = coin::from_balance(unstake_output, ctx);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(unstake_output, sender);
        if (balance::value(&reward) > 0) {
            let reward = coin::from_balance(reward, ctx);
            transfer::public_transfer(reward, sender);
        } else {
            balance::destroy_zero(reward);
        }        
    }

    public entry fun claim_penalty<S, R>(
        admin_cap: &AdminCap,
        fountain: &mut Fountain<S, R>,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let penalty = core::claim_penalty(admin_cap, fountain);
        transfer::public_transfer(
            coin::from_balance(penalty, ctx),
            recipient,
        );
    }

    public entry fun withdraw_from_source<S, R>(
        cap: &AdminCap,
        fountain: &mut Fountain<S, R>,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let fund = core::withdraw_from_source<S, R>(
            cap,
            fountain,
            amount,
        );
        transfer::public_transfer(coin::from_balance(fund, ctx), recipient);
    }
}
