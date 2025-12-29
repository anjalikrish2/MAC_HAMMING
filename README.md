 Reversible MAC with Hamming ECC

8-bit MAC unit using reversible logic gates + Hamming(21,16) error correction.

 Features
- **Reversible gates only** (Peres, Feynman,)
- **Vedic 8×8 multiplier** with reversible adders
- **Hamming(21,16)** - corrects 1-bit errors


  


## Hamming Code
- **16 data bits** → **21 bits** (16 data + 5 parity)
- **Parity positions**: 1, 2, 4, 8, 16 (powers of 2)
- **Syndrome** points to error location
- **All XOR ops** use reversible Peres gates

## Key Modules
- `tt_um_db_MAC` - Top-level MAC
- `hamming_21_16_encoder_peres` - Reversible encoder
- `hamming_21_16_decoder_peres` - Decoder with correction
- `peres_multi_xor` - Cascaded XOR using Peres gates





