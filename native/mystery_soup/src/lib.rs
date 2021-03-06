use randomize::PCG32;
use rustler::{resource, Env, Error, NifResult, NifStruct, Term};

#[derive(NifStruct, Clone)]
#[module = "MysterySoup.PCG32"]
struct RngState {
    state: u64,
    inc: u64,
}

#[rustler::nif]
fn init_state() -> NifResult<RngState> {
    let mut arr = [0_u64, 0];
    if getrandom::getrandom(bytemuck::bytes_of_mut(&mut arr)).is_err() {
        return Err(Error::Atom("sys_rand_err"));
    }
    let [state, inc] = arr;
    Ok(RngState { state, inc })
}

#[rustler::nif]
fn next(term_state: RngState) -> (u32, RngState) {
    next_prv(term_state)
}

fn next_prv(term_state: RngState) -> (u32, RngState) {
    let RngState { state, inc } = term_state;
    let mut rng = PCG32 { state, inc };
    (
        rng.next_u32(),
        RngState {
            state: rng.state,
            inc: rng.inc,
        },
    )
}

#[rustler::nif]
fn next_float(term_state: RngState) -> (f32, RngState) {
    let (mut bit_src, mut term_state) = next_prv(term_state);
    let mut bit_count = 0;

    let low: f32 = 0.0;
    let high: f32 = 1.0;

    let low_exp = (low.to_bits() as i32 >> 23) & 0xff;
    let high_exp = (high.to_bits() as i32 >> 23) & 0xff;

    let mut exp = high_exp.wrapping_sub(1);

    while exp > low_exp {
        if get_bit(&mut term_state, &mut bit_src, &mut bit_count) == 1 {
            break;
        }

        exp = exp.wrapping_sub(1);
    }

    let (mantissa, mut term_state) = next_prv(term_state);

    let mantissa = mantissa & 0x7fffff;

    if mantissa == 0 && get_bit(&mut term_state, &mut bit_src, &mut bit_count) == 1 {
        exp = exp.wrapping_add(1);
    }

    let result = ((exp as u32) << 23) | mantissa;

    (f32::from_bits(result), term_state)
}

fn get_bit(term_state: &mut RngState, bits: &mut u32, i: &mut u32) -> u32 {
    if *i == 0 {
        let (new_bits, new_state) = next_prv(term_state.clone());

        *bits = new_bits;
        *term_state = new_state;
        *i = 31;
    }

    let bit = *bits & 1;
    *bits = *bits >> 1;

    *i -= 1;

    bit
}

fn load(env: Env<'_>, _: Term<'_>) -> bool {
    resource!(RngState, env);
    true
}

rustler::init!(
    "Elixir.MysterySoup.PCG32.Nif",
    [init_state, next, next_float],
    load = load
);

