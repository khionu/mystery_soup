use randomize::PCG32;
use rustler::{resource, Env, Error, NifResult, ResourceArc, Term};

struct RngState {
    state: u64,
    inc: u64,
}

#[rustler::nif]
fn init_state() -> NifResult<ResourceArc<RngState>> {
    let mut arr = [0_u64, 0];
    if getrandom::getrandom(bytemuck::bytes_of_mut(&mut arr)).is_err() {
        return Err(Error::Atom("sys_rand_err"));
    }
    let [state, inc] = arr;
    Ok(ResourceArc::new(RngState { state, inc }))
}

#[rustler::nif]
fn next(term_state: ResourceArc<RngState>) -> (u32, ResourceArc<RngState>) {
    let RngState { state, inc } = *term_state;
    let mut rng = PCG32 { state, inc };
    (
        rng.next_u32(),
        ResourceArc::new(RngState {
            state: rng.state,
            inc: rng.inc,
        }),
    )
}

fn load(env: Env<'_>, _: Term<'_>) -> bool {
    resource!(RngState, env);
    true
}

rustler::init!(
    "Elixir.MysterySoup.PCG32.Nif",
    [init_state, next],
    load = load
);
