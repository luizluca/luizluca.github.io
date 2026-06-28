# Register and Structure Mapping (RTL8367x / RTL8365MB Families)

This document centralizes the hardware mapping of all supported generations
(Families A, B, C, and D). The source of truth for the hardware behavior and
correct mapping are the original vendor drivers (Realtek SDKs). The `rtl8365mb`
driver (Linux upstream) is used here only as a baseline to limit and define the
scope of which registers, tables, and logic we must look for in the vendor's
source code.

Specifically, Families B, C, and D correspond directly to the hardware supported
by the vendor APIs RTL8367B, RTL8367C, and RTL8367D, respectively. Family A, on
the other hand, maps to the legacy RTL8370 vendor API, which encompasses and
defines the behavior for devices such as the RTL8367R.

Some models have a version suffix like -VB or -VC. They do not have direct
relation with the family letter but it might indicate that it is a newer version
of an existing model from a previous family.

The columns and descriptions of all families have been strictly validated
against the respective vendor structs (`rtl8370_reg.h`, `rtl8367b_reg.h`, `
rtl8367c_reg.h`, and `rtl8367d_reg.h`). **Bold hexadecimal values** indicate a
difference in address, layout, or behavior between the specific Family and the
Family C baseline.

## 1\. Exhaustive Register Mapping (`rtl8365mb` baseline)

In this section, `p` indicates the logical/physical port index, `e` indicates
the extension port index (EXT0~2), and `msti` indicates the Multiple Spanning
Tree Instance. All registers on the SMI bus are 16-bit wide.

### 1.1. Identification, System, and Interrupts


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|SDK Name|Function / Usage|
|-|-|-|-|-|-|-|
|`CHIP_ID_REG`|`0x1300`|`0x1300`|`0x1300`|`0x1300`|`RTL83XX_REG_CHIP_NUMBER`|Family/Chip ID.|
|`CHIP_VER_REG`|`0x1301`|`0x1301`|`0x1301`|`0x1301`|`RTL83XX_REG_CHIP_VER`|Silicon version and chip revision.|
|`CHIP_RESET_REG`|`0x1322`|`0x1322`|`0x1322`|`0x1322`|`RTL83XX_REG_CHIP_RESET`|Soft system reset configuration.|
|`MAGIC_REG`|`0x13C2`|`0x13C2`|`0x13C2`|`0x13C2`|`RTL83XX_REG_MAGIC_ID`|Unlock register (required value is `0x0249`).|
|`INTR_POLARITY_REG`|`0x1100`|`0x1100`|`0x1100`|`0x1100`|`RTL83XX_REG_INTR_CTRL`|Configures global IRQ pin polarity and events.|
|`INTR_CTRL_REG`|`0x1101`|`0x1101`|`0x1101`|`0x1101`|`RTL83XX_REG_INTR_IMR`|Interrupt Mask Register (Interrupt Enable).|
|`INTR_STATUS_REG`|`0x1102`|`0x1102`|`0x1102`|`0x1102`|`RTL83XX_REG_INTR_IMS`|Interrupt Status Register (Pending Interrupts).|

**Bit Details (Validated Across All Families):**

#### 1.1.1. CHIP_ID_REG (0x1300)

This is a 16-bit read-only register that returns the hardware chip family and
model identifier. The exact value depends on the switch model detected by the
SDK procedures:

* **Family A (RTL8370 / RTL8367):** Returns `0x6088` (for RTL8367R).
* **Family B (RTL8367B):** Unknown retuned value. 
* **Family C (RTL8367C / RTL8370B / RTL8365MB / RTL8364B / RTL8363SC_VB):**
  Returns `0x0276`, `0x0597`, or `0x6367` (for RTL8367C, RTL8367S, RTL8367SB,
  RTL8367RB-VB), `0x0652` or `0x6368` (for RTL8370B), or `0x0801` or `0x6511`
  (for RTL8364B or RTL8363SC_VB).
* **Family D (RTL8367D):** Returns `0x6642` (for RTL8367D).

#### 1.1.2. CHIP_VER_REG (0x1301)

This register contains hardware identification subfields. The naming of the
fields changes between older generations (Families A and B) and newer ones
(Families C and D):

* **Family A, B:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RLVID     |     MCID      |     BOID      |   RESERVED    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **RLVID (15:12)**: `RLVID_MASK` (`0xF000`). 4-bit Realtek Version/Revision
    ID.
  * **MCID (11:8)**: `MCID_MASK` (`0xF00`). 4-bit Manufacturing/Chip ID.
  * **BOID (7:4)**: `BOID_MASK` (`0xF0`). 4-bit Board/Sub-model ID.

* **Family C, D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     VERID     |     MCID      |   MODEL_ID    |   RESERVED| A |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **VERID (15:12)**: `VERID_MASK` (`0xF000`). 4-bit Version/Revision ID
    (mentioned as `RLVID` in family B).
  * **MCID (11:8)**: `MCID_MASK` (`0xF00`). 4-bit Manufacturing/Chip ID.
  * **MODEL_ID (7:4)**: `MODEL_ID_MASK` (`0xF0`). 4-bit Model/Sub-model ID
    (mentioned as `BOID`).
  * **A (0:0)**: `AFE_VERSION_MASK` (`0x1`). 1-bit Analog Front-End Version.

#### 1.1.3. CHIP_RESET_REG (0x1322)

This register contains system soft reset control bits.

* **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED    |NIC|805|RSV|CFG|SW |CHP|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **NIC (5:5)**: `NIC_RST`. Network Interface Controller Reset.
  * **805 (4:4)**: `DW8051_RST`. DW8051 MCU Reset.
  * **CFG (2:2)**: `CONFIG_RST`. Configuration register soft reset.
  * **SW (1:1)**: `SW_RST`. Software Reset (`0x0002`). Clears soft state.
  * **CHP (0:0)**: `CHIP_RST`. Chip (ASIC) full reset (`0x0001`).
  * *Note*: Bits 3 (`SDS_RST`) and 6 (`GPHY_RESET`) are reserved and not
    supported on Family A.

* **Family B, C, D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                       RESERVED    |GPH|NIC|805|SDS|CFG|SW |CHP|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **GPH (6:6)**: `GPHY_RESET`. Gigphy (Copper PHYs) Reset.
  * **NIC (5:5)**: `NIC_RST`. Network Interface Controller Reset.
  * **805 (4:4)**: `DW8051_RST`. Internal DW8051 MCU Reset.
  * **SDS (3:3)**: `SDS_RST`. SerDes Reset.
  * **CFG (2:2)**: `CONFIG_RST`. Configuration register soft reset.
  * **SW (1:1)**: `SW_RST`. Software Reset (`0x0002`). Clears soft state.
  * **CHP (0:0)**: `CHIP_RST`. Chip (ASIC) full reset (`0x0001`).

#### 1.1.4. MAGIC_REG (0x13C2)

This is a 16-bit write-only register used to unlock access to protected
configuration registers.

* **Families A, B, C, and D:** Must be written with the key value `0x0249`
  (represented as `RTL83XX_REG_MAGIC_ID` or `RTL8365MB_MAGIC_VALUE`) to disable
  write protection on certain ASIC registers (such as chip ID and version
  registers) prior to accessing them. Must be written with `0x0000` to re-lock.

#### 1.1.5. INTR_POLARITY_REG (0x1100)

This register configures global interrupt pin polarity and specific sub-system
polarity settings.

* **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                    |805|POL|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **POL (0:0)**: `INTR_POLARITY`. Global IRQ pin polarity. `0` = Active High, `
    1` = Active Low.
  * **805 (1:1)**: `INTR_POLARITY_8051`. Polarity selector for internal DW8051
    MCU interrupt.

* **Family B, C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                                                   RESERVED|POL|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **POL (0:0)**: `INTR_CTRL`. Global IRQ pin polarity. `0` = Active High, `1`
    = Active Low.

* **Family D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                    |THR|POL|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **POL (0:0)**: `INTR_POLARITY`. Global IRQ pin polarity. `0` = Active High, `
    1` = Active Low.
  * **THR (1:1)**: `CFG_INT_TM_NEG`. Internal thermal sensor interrupt polarity
    configuration (`0` = Positive trigger, `1` = Negative trigger).

#### 1.1.6. INTR_CTRL_REG (0x1101)

This register is the Interrupt Mask Register (IMR) which controls whether
individual interrupt events trigger the global IRQ pin.

* **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |805|LPD|GRN|SPC|SPD|LRN|MET|LNK|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **805 (7:7)**: `INTERRUPT_8051`. Internal 8051 MCU interrupt.
  * **LPD (6:6)**: `LOOP_DETECTION`. Loop Detection triggered.
  * **GRN (5:5)**: `GREEN_TIMER`. Green Ethernet Timer interrupt.
  * **SPC (4:4)**: `SPECIAL_CONGEST`. Special Congestion event.
  * **SPD (3:3)**: `SPEED_CHANGE`. Port Speed/Link Change.
  * **LRN (2:2)**: `LEARN_OVER`. MAC Learning Limit Exceeded.
  * **MET (1:1)**: `METER_EXCEEDED`. Bandwidth Meter Exceeded.
  * **LNK (0:0)**: `LINK_CHANGE`. Port Link Status Change.

* **Family B:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED    | SS|UPS|ACL|CAB|805|LPD|GRN|SPC|SPD|LRN|MET|LNK|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **SS (11:11)**: `SLIENT_START`. Silent Start event (mispelled?).
  * **UPS (10:10)**: `UPS_EVENT`. Uninterruptible Power Supply event.
  * **ACL (9:9)**: `ACL_ACTION`. Access Control List Action hit.
  * **CAB (8:8)**: `CABLE_DIAG_FIN`. Cable Diagnosis Finished.
  * **805 (7:7)**: `INTERRUPT_8051`. Internal 8051 MCU interrupt.
  * **LPD (6:6)**: `LOOP_DETECTION`. Loop Detection triggered.
  * **GRN (5:5)**: `GREEN_TIMER`. Green Ethernet Timer interrupt.
  * **SPC (4:4)**: `SPECIAL_CONGEST`. Special Congestion event.
  * **SPD (3:3)**: `SPEED_CHANGE`. Port Speed/Link Change.
  * **LRN (2:2)**: `LEARN_OVER`. MAC Learning Limit Exceeded.
  * **MET (1:1)**: `METER_EXCEEDED`. Bandwidth Meter Exceeded.
  * **LNK (0:0)**: `LINK_CHANGE`. Port Link Status Change.

* **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |SS2| SS|RSV|ACL|CAB|805|LPD|GRN|SPC|SPD|LRN|MET|LNK|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **SS2 (12:12)**: `SLIENT_START_2`. Silent Start 2 event (mispelled?).
  * **SS (11:11)**: `SLIENT_START`. Silent Start event (mispelled?).
  * **ACL (9:9)**: `ACL_ACTION`. Access Control List Action hit.
  * **CAB (8:8)**: `CABLE_DIAG_FIN`. Cable Diagnosis Finished.
  * **805 (7:7)**: `INTERRUPT_8051`. Internal 8051 MCU interrupt.
  * **LPD (6:6)**: `LOOP_DETECTION`. Loop Detection triggered.
  * **GRN (5:5)**: `GREEN_TIMER`. Green Ethernet Timer interrupt.
  * **SPC (4:4)**: `SPECIAL_CONGEST`. Special Congestion event.
  * **SPD (3:3)**: `SPEED_CHANGE`. Port Speed/Link Change.
  * **LRN (2:2)**: `LEARN_OVER`. MAC Learning Limit Exceeded.
  * **MET (1:1)**: `METER_EXCEEDED`. Bandwidth Meter Exceeded.
  * **LNK (0:0)**: `LINK_CHANGE`. Port Link Status Change.

* **Family D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |THR| SS|RSV|ACL|CAB|805|LPD|RSV|SPC|SPD|LRN|MET|LNK|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **THR (12:12)**: `THERMAL_ALARM`. Thermal sensor alarm trigger.
  * **SS (11:11)**: `SLIENT_START`. Silent Start event (mispelled?).
  * **ACL (9:9)**: `ACL_ACTION`. Access Control List Action hit.
  * **CAB (8:8)**: `CABLE_DIAG_FIN`. Cable Diagnosis Finished.
  * **805 (7:7)**: `INTERRUPT_8051`. Internal 8051 MCU interrupt.
  * **LPD (6:6)**: `LOOP_DETECTION`. Loop Detection triggered.
  * **SPC (4:4)**: `SPECIAL_CONGEST`. Special Congestion event.
  * **SPD (3:3)**: `SPEED_CHANGE`. Port Speed/Link Change.
  * **LRN (2:2)**: `LEARN_OVER`. MAC Learning Limit Exceeded.
  * **MET (1:1)**: `METER_EXCEEDED`. Bandwidth Meter Exceeded.
  * **LNK (0:0)**: `LINK_CHANGE`. Port Link Status Change.
  * *Note*: Bit 5 (`GREEN_TIMER`) and Bit 10 (`UPS_EVENT`) are reserved and not
    supported on Family D.

#### 1.1.7. INTR_STATUS_REG (0x1102)

This register is the Interrupt Status Register (IMS/ISR) which records pending
interrupt events.

* **Families A, B, C, and D:** The bit layout and names correspond exactly to `
  INTR_CTRL_REG` (0x1101) for each respective family. A bit set to `1` indicates
  that the corresponding event is active/pending. Writing `1` to a bit clears
  that event's pending status. Description of the events matches `INTR_CTRL_REG`
  (0x1101).

### 1.2. Port Control, MAC and Isolation


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|Function / Usage|
|-|-|-|-|-|-|
|`PORT_ISOLATION_REG(p)`|`0x08A2 + p`|`0x08A2 + p`|`0x08A2 + p`|`0x08A2 + p`|Allowed ports matrix (`PORT_ISOLATION_PORTx_MASK` in SDK).|
|`PORT_LINKDOWN_IND`|`0x1106`|`0x1106`|`0x1106`|`0x1106`|Portmask of Link Down events.|
|`PORT_LINKUP_IND`|`0x1107`|`0x1107`|`0x1107`|`0x1107`|Portmask of Link Up events.|
|`PORT_MISC_CFG_REG(p)`|`0x000E + (p\\\<<5)`|`0x000E + (p\\\<<5)`|`0x000E + (p\\\<<5)`|`0x000E + (p\\\<<5)`|Miscellaneous MAC configs (`PORTx_MISC_CFG` in SDK).|
|`CFG0_MAX_LEN_REG`|`\\\**Not found**`|`\\\**Not found**`|`0x088C`|`0x088C`|Max Frame Length allowed (MTU).|
|`MAX_LENGTH_LIMINT_IPG`|`0x1200`|`0x1200`|`0x1200`|`0x1200`|Max Frame Length allowed (MTU) in fixed steps.|

**Bit Details (Validated Across All Families):**

#### 1.2.1. PORT_ISOLATION_REG(p) (0x08A2 + p)

This register sets the port isolation mask for port `p`. Packets egressing port `
p` can only be forwarded to ports set in the `PORT_MASK`.

* **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           PORT_MASK                           |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (15:0)**: 16-bit mask representing allowed destination ports
    (ports 0 to 15).

* **Family B, C, D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RESERVED      |                 PORT_MASK                 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (10:0)**: 11-bit mask representing allowed destination ports
    (ports 0 to 10).

#### 1.2.2. PORT_LINKDOWN_IND (0x1106)

This register indicates which ports triggered a link down state transition.

* **Family A:** Uses a 16-bit mask (15:0) corresponding to ports 0 to 15.
* **Families B, C, and D:** Uses an 11-bit mask (10:0) corresponding to ports 0
  to 10. Bits 15:11 are reserved.

#### 1.2.3. PORT_LINKUP_IND (0x1107)

This register indicates which ports triggered a link up state transition.

* **Family A:** Uses a 16-bit mask (15:0) corresponding to ports 0 to 15.
* **Families B, C, and D:** Uses an 11-bit mask (10:0) corresponding to ports 0
  to 10. Bits 15:11 are reserved.

#### 1.2.4. PORT_MISC_CFG_REG(p) (0x000E + (p\<<5))

This register configures various MAC and flow control features per port `p`.

* **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     TIMER     |IBF|IBI|RXS|CRC|RSV|MAC|VL_EGR |   CONG_TIME   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **TIMER (15:12)**: `TIMER`. Miscellaneous timer configurations.
  * **IBF (11:11)**: `INGRESSBW_FLOWCTRL`. Enable flow control on ingress
    bandwidth limit.
  * **IBI (10:10)**: `INGRESSBW_IFG`. Include Inter-Frame Gap on ingress
    bandwidth calculations.
  * **RXS (9:9)**: `RX_SPC`. Special frame RX packet classification.
  * **CRC (8:8)**: `CRC_SKIP`. Egress CRC generation bypass.
  * **MAC (6:6)**: `MAC_LOOPBACK`. Loopback at the MAC interface layer.
  * **VL_EGR (5:4)**: `VLAN_EGRESS_MODE`. VLAN Egress Tagging rule (0=Keep Tag,
    1=Untag, 2=Tag).
  * **CONG_TIME (3:0)**: `CONGESTION_SUSTAIN_TIME`. Sustain thresholds for
    egress queue congestion.

* **Family B, C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| ST|TXI|FCI| D1|IBF|IBI|RXS|CRC|PTX|MAC|VL_EGR |   CONG_TIME   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **ST (15:15)**: `SMALL_TAG_IPG`. Inter-packet gap configuration for small
    tags.
  * **TXI (14:14)**: `TX_ITFSP_MODE`. IPG mode on TX path.
  * **FCI (13:13)**: `FLOWCTRL_INDEP`. Independent flow-control state.
  * **D1 (12:12)**: `DOT1Q_REMARK_ENABLE`. Enable 802.1p priority remarking.
  * **IBF (11:11)**: `INGRESSBW_FLOWCTRL`. Enable flow control on ingress
    bandwidth limit.
  * **IBI (10:10)**: `INGRESSBW_IFG`. Include Inter-Frame Gap on ingress
    bandwidth calculations.
  * **RXS (9:9)**: `RX_SPC`. Special frame RX packet classification.
  * **CRC (8:8)**: `CRC_SKIP`. Egress CRC generation bypass.
  * **PTX (7:7)**: `PKTGEN_TX_FIRST`. Packet generator tx first logic.
  * **MAC (6:6)**: `MAC_LOOPBACK`. Loopback at the MAC interface layer.
  * **VL_EGR (5:4)**: `VLAN_EGRESS_MODE`. VLAN Egress Tagging rule (0=Keep Tag,
    1=Untag, 2=Tag).
  * **CONG_TIME (3:0)**: `CONGESTION_SUSTAIN_TIME`. Sustain thresholds for
    egress queue congestion.

* **Family D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| ST|TXI|RSV| D1|IBF|IBI|RXS|CRC|RSV|MAC|VL_EGR |   CONG_TIME   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **ST (15:15)**: `SMALL_TAG_IPG`. Inter-packet gap configuration for small
    tags.
  * **TXI (14:14)**: `TX_ITFSP_MODE`. IPG mode on TX path.
  * **D1 (12:12)**: `DOT1Q_REMARK_ENABLE`. Enable 802.1p priority remarking.
  * **IBF (11:11)**: `INGRESSBW_FLOWCTRL`. Enable flow control on ingress
    bandwidth limit.
  * **IBI (10:10)**: `INGRESSBW_IFG`. Include Inter-Frame Gap on ingress
    bandwidth calculations.
  * **RXS (9:9)**: `RX_SPC`. Special frame RX packet classification.
  * **CRC (8:8)**: `CRC_SKIP`. Egress CRC generation bypass.
  * **MAC (6:6)**: `MAC_LOOPBACK`. Loopback at the MAC interface layer.
  * **VL_EGR (5:4)**: `VLAN_EGRESS_MODE`. VLAN Egress Tagging rule (0=Keep Tag,
    1=Untag, 2=Tag).
  * **CONG_TIME (3:0)**: `CONGESTION_SUSTAIN_TIME`. Sustain thresholds for
    egress queue congestion.

#### 1.2.5. CFG0_MAX_LEN_REG (0x088C)

This register defines the maximum frame length (MTU configuration) allowed on
the switch.

* **Families A and B:** Not supported at this specific address (Family A and B
  SDKs use `MAX_LENGTH_LIMINT_IPG` register, which sets the maximum frame in fixed steps.
* **Families C and D:** Located at `0x088C` (`RTL8367C_REG_MAX_LEN_RX_TX_CFG0`
  in the SDK), which configures global MTU limits for standard Ethernet frames.

#### 1.2.6. MAX_LENGTH_LIMINT_IPG (0x1200)

TODO: fill the docs.
Family C sets this to MAX in jam table. Check other families.

### 1.3. Extension Ports (EXT0, EXT1, EXT2)

Family C and D support up to three extension ports (EXT0, EXT1, and EXT2).
Family A and B only support EXT0 and EXT1.


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|SDK Name|Function / Usage|
|-|-|-|-|-|-|-|
|`DIGITAL_IF_SELECT(EXT0/1)`|`0x1305`|`0x1305`|`0x1305`|`0x1305`|`RTL83XX_REG_DIGITAL_INTERFACE_SELECT`|EXT0 and EXT1 MAC Interface Mode selectors.|
|`DIGITAL_IF_SELECT(EXT2)`|`\**N/A**`|`0x13C3`|`0x13C3`|`0x13C3`|`RTL83XX_REG_DIGITAL_INTERFACE_SELECT_1`|EXT2 MAC Interface Mode selector.|
|`DIGITAL_IF_FORCE(EXT0)`|`0x1310`|`0x1310`|`0x1310`|`0x1310`|`RTL83XX_REG_DIGITAL_INTERFACE0_FORCE`|EXT0 Link Force mode and parameters.|
|`DIGITAL_IF_FORCE(EXT1)`|`0x1311`|`0x1311`|`0x1311`|`0x1311`|`RTL83XX_REG_DIGITAL_INTERFACE1_FORCE`|EXT1 Link Force mode and parameters.|
|`DIGITAL_IF_FORCE(EXT2)`|`\**N/A**`|`0x13C4`|`0x13C4`|`0x13C4`|`RTL83XX_REG_DIGITAL_INTERFACE2_FORCE`|EXT2 Link Force mode and parameters.|
|`EXT_RGMXF_REG(EXT0)`|`0x1306`|`0x1306`|`0x1306`|`0x1306`|`RTL83XX_REG_EXT0_RGMXF`|EXT0 RGMII TX/RX clock delay and inversion.|
|`EXT_RGMXF_REG(EXT1)`|`0x1307`|`0x1307`|`0x1307`|`0x1307`|`RTL83XX_REG_EXT1_RGMXF`|EXT1 RGMII TX/RX clock delay and inversion.|
|`EXT_RGMXF_REG(EXT2)`|`\**N/A**`|`0x13C5`|`0x13C5`|`0x13C5`|`RTL83XX_REG_EXT2_RGMXF`|EXT2 RGMII TX/RX clock delay and inversion.|

**Bit Details (Validated Across All Families):**

#### 1.3.1. DIGITAL_IF_SELECT(EXT0/1) (0x1305)

This register selects the MAC interface mode for EXT0 and EXT1 ports.

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|COL|CRS|SK1|SK0|   RESERVED    |   EXT1_SEL    |   EXT0_SEL    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **COL (15:15)**: `ORG_COL`. Original Collision signal behavior configuration.
  * **CRS (14:14)**: `ORG_CRS`. Original Carrier Sense signal behavior.
  * **SK1 (13:13)**: `SKIP_MII_1_RXER`. Ignore RXER signal from EXT1 port.
  * **SK0 (12:12)**: `SKIP_MII_0_RXER`. Ignore RXER signal from EXT0 port.
  * **EXT1_SEL (7:4)**: `SELECT_GMII_1`. 4-bit interface mode for EXT1 (see mode
    table below).
  * **EXT0_SEL (3:0)**: `SELECT_GMII_0`. 4-bit interface mode for EXT0 (see mode
    table below).

#### 1.3.2. DIGITAL_IF_SELECT(EXT2) (0x13C3)

This register selects the MAC interface mode for EXT2 port.

* **Families B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                       RESERVED            |SK2|   EXT2_SEL    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **SK2 (4:4)**: `SKIP_MII_2_RXER`. Ignore RXER signal from EXT2 port.
  * **EXT2_SEL (3:0)**: `SELECT_GMII_2`. 4-bit interface mode for EXT2 (see mode
    table below).

**Supported Interface Modes (applies to all EXTx_SEL fields):**


- `0` – `DISABLE` – Port disabled (supported by all families)
- `1` – `RGMII` – Reduced Gigabit MII (supported by all families)
- `2` – `MII_MAC` – MII in MAC mode (supported by all families)
- `3` – `MII_PHY` – MII in PHY mode (supported by all families)
- `4` – `TMII_MAC` – Turbo‑MII in MAC mode (supported by all families)
- `5` – `TMII_PHY` – Turbo‑MII in PHY mode (supported by all families)
- `6` – `GMII` – Gigabit MII (supported by all families)
- `7` – `RMII_MAC` – Reduced MII in MAC mode (supported by all families)
- `8` – `RMII_PHY` – Reduced MII in PHY mode (supported by all families)
- `9` – `SGMII` – Serial‑Gigabit MII (SerDes) – supported only by families C and D
- `10` – `HSGMII` – High‑speed SGMII (2.5 G SerDes) – supported only by families C and D
- `11` – `1000X_100FX` – SFP auto‑detect (1000Base‑X or 100Base‑FX) – supported only by families C and D
- `12` – `1000X` – SFP 1000Base‑X only – supported only by families C and D
- `13` – `100FX` – SFP 100Base‑FX only – supported only by families C and D
*Families A and B lack modes 9‑13 (SGMII, HSGMII, 1000X_100FX, 1000X, 100FX).*

#### 1.3.3. DIGITAL_IF_FORCE(EXTx) (0x1310 / 0x1311 / 0x13C4)

This register forces the link parameters for an extension port when force mode
is active.

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED|EN |   RESERVED    |NWY|TXP|RXP|LNK|RSV|DPX|  SPD  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **EN (12:12)**: `GMII_x_FORCE` (`0x1000`). Enable Force Mode. `1` = force
    link parameters, `0` = auto-negotiation.
  * **NWY (7:7)**: Force NWAY. MAC-side Auto-negotiation advertisement enable.
  * **TXP (6:6)**: Force TX Pause advertisement.
  * **RXP (5:5)**: Force RX Pause advertisement.
  * **LNK (4:4)**: Force Link state. `1` = Force Link UP.
  * **DPX (2:2)**: Force Duplex. `1` = Full Duplex, `0` = Half Duplex.
  * **SPD (1:0)**: Force Speed. `0` = 10 Mbps, `1` = 100 Mbps, `2` = 1000 Mbps.

#### 1.3.4. EXT_RGMXF_REG(EXTx) (0x1306 / 0x1307 / 0x13C5)

This register configures RGMII TX/RX clock delay and optional clock inversion
per extension port.

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                   RESERVED        |TXI|RXI|  TXD  |    RXD    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **TXI (6:6)**: `RGTX_INV`. Invert RGMII TX clock polarity.
  * **RXI (5:5)**: `RGRX_INV`. Invert RGMII RX clock polarity.
  * **TXD (4:3)**: TX delay configuration (2-bit). Controls internal TX clock
    delay taps.
  * **RXD (2:0)**: `RXDELAY`. 3-bit RX clock delay stages.
  * *Note*: The Linux driver (`rtl8365mb_main.c`) uses `TXDELAY_MASK = 0x0008`
    (bit 3 only) and `RXDELAY_MASK = 0x0007` for a simplified 1-bit TX + 3-bit
    RX model.

### 1.4. Flooding, MSTI, and CPU Port


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|SDK Name|Function / Usage|
|-|-|-|-|-|-|-|
|`MSTI_CTRL_REG(msti, p)`|`0x0A00 + (msti\*2) + (p/8)`|`0x0A00 + (msti\*2) + (p/8)`|`0x0A00 + (msti\*2) + (p/8)`|`0x0A00 + (msti\*2) + (p/8)`|`RTL83XX_REG_MSTI_CTRL`|Multiple Spanning Tree Instance state per port.|
|`UNKNOWN_UC_FLOOD`|`0x0890`|`0x0890`|`0x0890`|`0x0890`|`RTL83XX_REG_PORTMASK_UNKNOWN_UNICAST`|Portmask for unknown Unicast flooding destination.|
|`UNKNOWN_MC_FLOOD`|`0x0891`|`0x0891`|`0x0891`|`0x0891`|`RTL83XX_REG_PORTMASK_UNKNOWN_MULTICAST`|Portmask for unknown Multicast flooding destination.|
|`UNKNOWN_BC_FLOOD`|`0x0892`|`0x0892`|`0x0892`|`0x0892`|`RTL83XX_REG_PORTMASK_BROADCAST`|Portmask for Broadcast flooding destination.|
|`CPU_PORT_MASK_REG`|`0x1219`|`0x1219`|`0x1219`|`0x1219`|`REG_CPU_PORT_MASK`|CPU Port Mask configuration.|
|`CPU_CTRL_REG`|`0x121A`|`0x121A`|`0x121A`|`0x121A`|`RTL83XX_REG_CPU_CTRL`|CPU Tag insertion/removal and Trap port control.|

**Bit Details (Validated Across All Families):**

#### 1.4.1. MSTI_CTRL_REG(msti, p) (0x0A00 + (msti\*2) + (p/8))

Each 16-bit register packs STP state for 8 ports (2 bits each). The register
address encodes the MSTI index and port group.

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| PORT_7| PORT_6| PORT_5| PORT_4| PORT_3| PORT_2| PORT_1| PORT_0|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_x (2 bits)**: STP state for port `x` in MSTI `msti`. Field offset = `
    (p % 8) * 2`.
    * `0` = Disabled (blocking RX and TX)
    * `1` = Blocking (receiving BPDUs only)
    * `2` = Learning (MAC learning, no forwarding)
    * `3` = Forwarding (normal traffic forwarding)

#### 1.4.2. UNKNOWN_UC_FLOOD / UNKNOWN_MC_FLOOD / UNKNOWN_BC_FLOOD (0x0890 / 0x0891 / 0x0892)

These three registers define the flooding portmask for their respective traffic
class.

* **Family A:** Uses a 16-bit mask (15:0) for ports 0 to 15.
* **Families B, C, and D:** Uses an 11-bit mask (10:0) for ports 0 to 10. Bits
  15:11 are reserved.

#### 1.4.3. CPU_PORT_MASK_REG (0x1219)

This register defines which ports are considered CPU ports for CPU tag
processing.

* **Family A:** Uses a 16-bit mask (15:0) for ports 0 to 15.
* **Families B, C, and D:** Uses an 11-bit mask (10:0) for ports 0 to 10. Bits
  15:11 are reserved.

#### 1.4.4. CPU_CTRL_REG (0x121A)

This register controls CPU tag insertion, removal, and the trap port
destination.

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RESERVED      |EX |FMT|RSV|RX |POS|  TRAP_PORT|INSMODE|EN |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **EX (10:10)**: `TRAP_PORT_EXT`. Direct trapped traffic to an extension port.
  * **FMT (9:9)**: `TAG_FORMAT`. Defines Realtek CPU Tag structure format.
  * **RX (7:7)**: `RXBYTECOUNT`. Append RX frame length metadata in CPU tags.
  * **POS (6:6)**: `TAG_POSITION`. Insertion position: `0` = After SA
    (standard), `1` = Prefix (before DA).
  * **TRAP_PORT (5:3)**: 3-bit logical port ID directing where trapped/redirected
    system traffic is sent.
  * **INSMODE (2:1)**: `INSERTMODE`. `0` = Disable CPU tag insertion, `1` =
    Insert into all CPU egress frames, `2` = Insert into Trapped/Redirected
    frames only.
  * **EN (0:0)**: `ENABLE`. Global activation of Realtek CPU Tag processing.

### 1.5. VLAN Configurations


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|SDK Name|Function / Usage|
|-|-|-|-|-|-|-|
|`VLAN_CTRL_REG`|`0x07A8`|`0x07A8`|`0x07A8`|`0x07A8`|`RTL83XX_REG_VLAN_CTRL`|Global VLAN support activation (bit 0 = enable).|
|`VLAN_PVID_CTRL_REG(p)`|`0x0700 + (p/2)`|`0x0700 + (p/2)`|`0x0700 + (p/2)`|`0x0700 + (p/2)`|`RTL83XX_REG_PORT_PVID_CTRL`|Port Default VID/PVID (2 ports per register, 8 bits each).|
|`VLAN_ACCEPT_FRAME(p)`|`0x07AA + (p/4)`|`0x07AA + (p/4)`|`0x07AA + (p/4)`|`0x07AA + (p/4)`|`RTL83XX_REG_VLAN_ACCEPT_FRAME_TYPE`|Accept Frame Type rules (Tagged/Untagged) per port.|
|`VLAN_INGRESS_REG`|`0x07A9`|`0x07A9`|`0x07A9`|`0x07A9`|`RTL83XX_REG_VLAN_INGRESS_FILTER`|Ingress filtering activation portmask.|
|`VLAN_EGRESS_TRANS_REG(p)`|`\**Not found**`|`\**Not found**`|`0x09D0 + (p/4)`|`0x09D0 + (p/4)`|`RTL8367C_REG_VLAN_EGRESS_TRANSPARENT`|Egress VLAN transparency mapping per port.|
|`PORT_EFID_REG(p)`|`0x0A32 + (p/4)`|`0x0A32 + (p/4)`|`0x0A32 + (p/4)`|`0x0A32 + (p/4)`|`RTL83XX_REG_EFID`|Enhanced Filtering Database ID (EFID) mapping.|
|`VLAN_MC_BASE`|`0x0728`|`0x0728`|`0x0728`|`0x0728`|`RTL83XX_REG_VLAN_MEMBER_CONFIG_BASE`|Base for VLAN member config entries 0~31. Entry size: 4 words (64-bit) on Family A, 3 words (48-bit) on B/C/D.|

**Bit Details (Validated Across All Families):**

#### 1.5.1. VLAN_CTRL_REG (0x07A8)

This register globally enables the VLAN subsystem.

* **Families A, B, C, and D:** Bit 0 (`VLAN_CTRL_ENABLE`) enables the VLAN
  hardware engine. All other bits are reserved.

#### 1.5.2. VLAN_PVID_CTRL_REG(p) (0x0700 + (p/2))

Each register encodes the PVID for two ports (8 bits per port).

* **Families A, B, C, and D:** Bits 15:8 = PVID for port `p | 1`, bits 7:0 =
  PVID for port `p & ~1`.

#### 1.5.3. VLAN_ACCEPT_FRAME(p) (0x07AA + (p/4))

Each register encodes the frame acceptance mode for four ports (2 bits per
port).

* **Families A, B, C, and D:** 2-bit field per port. `0` = All frames, `1` =
  Tagged only, `2` = Untagged only.

#### 1.5.4. VLAN_INGRESS_REG (0x07A9)

This register activates ingress filtering on a per-port basis.

* **Family A:** Uses a 16-bit portmask (15:0) for ports 0 to 15.
* **Families B, C, and D:** Uses an 11-bit portmask (10:0) for ports 0 to 10.
  Bits 15:11 are reserved.

### 1.6. MAC Learning & Security


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|SDK Name|Function / Usage|
|-|-|-|-|-|-|-|
|`LUT_PORT_LEARN_LIMIT(p)`|`0x0A20 + p`|`0x0A20 + p`|`0x0A20 + p`|`0x0A20 + p`|`RTL83XX_REG_LUT_PORT_LEARN_LIMIT`|Limits maximum dynamically learned MACs per physical port.|

**Bit Details (Validated Across All Families):**

#### 1.6.1. LUT_PORT_LEARN_LIMIT(p) (0x0A20 + p)

This register defines the maximum number of MAC addresses that can be
dynamically learned on port `p`.

* **Families A, B, C, and D:** Bits 11:0 contain the learn limit count (0 =
  disable learning on port). Bits 15:12 are reserved.

### 1.7. MIB Counters (Statistics)

Polling MIB counters requires first specifying the target port/counter ID and
then retrieving results in a structured multi-register block.


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|SDK Name|Function / Usage|
|-|-|-|-|-|-|-|
|`MIB_ADDRESS_REG`|`0x10047`|`0x1004`|`0x1004`|`0x1004`|`RTL83XX_REG_MIB_ADDRESS`|Target Port and counter selection for MIB polling.|
|`MIB_ADDRESS_PORT_OFFSET`|`0x007C`|`0x007C`|`0x007C`|`0x007C`|`RTL83XX_MIB_PORT_OFFSET`|Per-port hardware offset for MIB address calculation. Not a register.|
|`MIB_CTRL0_REG`|`0x1005`|`0x1005`|`0x1005`|`0x1005`|`RTL83XX_REG_MIB_CTRL0`|Poll execution trigger, reset command, and busy flag.|
|`MIB_COUNTER_BASE`|`0x1000`|`0x1000`|`0x1000`|`0x1000`|`RTL83XX_REG_MIB_COUNTER_BASE`|Staging register block where the latched counter value resides.|

**MIB Address Calculation:**

- `MIB_Address = (0x007C * port + counter_offset) >> 2`

**Bit Details (Validated Across All Families):**

#### 1.7.1. MIB_CTRL0_REG (0x1005)

This register triggers and monitors the MIB counter polling operation.

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                    |RST| B |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **RST (1:1)**: MIB counter reset command (`0x0002`). Writing `1` clears
    selected counters.
  * **B (0:0)**: Busy flag (`0x0001`). Hardware sets to `1` during polling;
    clears to `0` when counter data is ready in `MIB_COUNTER_BASE`.

## 2\. Table Access and Indirect Mechanisms

All generations from RTL8370 onwards perfectly share the same Unified Table
mechanism (`0x0500`) and the OCP Indirect mechanism for PHYs (`0x1F00`). This
implies extremely high code reusability across families.

### 2.1. Indirect PHY Access (MDIO via OCP)

The CPU addresses the PHY registers through an indirect paging mechanism.


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|Function / Usage|
|-|-|-|-|-|-|
|`INDIRECT_ACCESS_CTRL`|`0x1F00`|`0x1F00`|`0x1F00`|`0x1F00`|Command (Bit 0) and Access type (Bit 1).|
|`INDIRECT_ACCESS_STATUS`|`0x1F01`|`0x1F01`|`0x1F01`|`0x1F01`|Internal transaction status.|
|`INDIRECT_ACCESS_ADDRESS`|`0x1F02`|`0x1F02`|`0x1F02`|`0x1F02`|Formatted PHY address.|
|`INDIRECT_ACCESS_WRITE`|`0x1F03`|`0x1F03`|`0x1F03`|`0x1F03`|Data to write to PHY.|
|`INDIRECT_ACCESS_READ`|`0x1F04`|`0x1F04`|`0x1F04`|`0x1F04`|Data read from PHY.|
|`GPHY_OCP_MSB_0_REG`|`\\\**Not found**`|`0x1D15`|`0x1D15`|`0x1D15`|(Bits 11:6) CPU OCPADR base.|
|`PHY_OCP_ADDR_PHYREG_BASE`|`0xA400`|`0xA400`|`0xA400`|`0xA400`|Base address for local PHY registers 0~31 OCP queries.|

**Bit Details (Validated Across All Families):**

#### 2.1.1. INDIRECT_ACCESS_CTRL (0x1F00)

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                    |RW | C |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **RW (1:1)**: Operation direction. `0` = Read PHY register, `1` = Write PHY
    register.
  * **C (0:0)**: Command trigger. Write `1` to execute transaction; hardware
    clears it to `0` upon completion.

**Addressing the PHY via OCP:**

- `OCP_Address = BASE | (phyNum << OFFSET) | phyReg`
- **Internal PHYs**: `BASE = 0x2000`, `OFFSET = 5`.
- **External PHYs**: `BASE = 0xA000`, `OFFSET = 9`.

#### 2.1.2. INDIRECT_ACCESS_ADDRESS (0x1F02)

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED    |    OCP_HI     |  PHYNUM   |      OCP_LO       |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **OCP_HI (11:8)**: Open Core Protocol Address high bits (`OCPADR\[9:6]`).
  * **PHYNUM (7:5)**: PHY ID / Port number (`PHYNUM\[2:0]`).
  * **OCP_LO (4:0)**: Open Core Protocol Address low bits (`OCPADR\[5:1]`).

### 2.2. The Unified Table Mechanism (`0x0500`)

The **Unified Central Mechanism** is located at base `0x0500` to operate L2 and
VLAN tables across all families.

**Central Registers:**

- `TABLE_CTRL_REG` (`0x0500`): Defines the Command and the Target Table.
- `TABLE_ACCESS_ADDR_REG` (`0x0501`): Index to access.
- `TABLE_STATUS_REG` (`0x0502`): Status returned by the hardware (BUSY, HIT).
- `TABLE_WRITE_BASE` (`0x0510` to `0x0519`): Staging area for Write operations.
- `TABLE_READ_BASE` (`0x0520` to `0x0529`): Staging area for Read operations.

#### 2.2.1. TABLE_CTRL_REG (0x0500)

* **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED    |     PORT      |RSV|  METHOD   |OP |   TABLE   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT (11:8)**: Target Port index (applicable for port-based lookups).
  * **METHOD (6:4)**: Access method selector.
  * **OP (3:3)**: Operation. `0` = Read, `1` = Write.
  * **TABLE (2:0)**: Target table selector.

#### 2.2.2. TABLE_STATUS_REG (0x0502)

* **Families A, B, C, and D:**

```

 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|EX |BSY|HIT| T |                ADDRESS_STATUS             |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **EX (14:14)**: Extension bit for Address (`ADDRESS_EXT`).
  * **BSY (13:13)**: `BUSY_FLAG`. `1` = Hardware is executing the command.
  * **HIT (12:12)**: `HIT_STATUS`. `1` = Entry was found during a lookup/search.
  * **T (11:11)**: `ADDR_TYPE`. Address type qualifier.
  * **ADDRESS_STATUS (10:0)**: Internal hardware index of the matched/written
    entry.

### 2.3. Meticulous Bitfield Comparison of RAM Tables

A deep validation of the table architectures shows major structural divergences
due to physical port limitations (16 ports on Family A versus 11 ports on
Family B, C, and D).

#### A. CVLAN (Customer VLAN) Table Layout Comparison

##### Family A (RTL8370) - 64-bit Structure (4 Words)

Family A requires 64-bits (4 registers) to host the full 16-bit physical port
member mask:

```
Family A CVLAN Word 0
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                          MBR [15:0]                           | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|  MSTI [3:0]   |                   FID [11:0]                  | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| R |LUR|         METERIDX [7:0]        |POL|   VBPRI   |EN | R | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |                  EVID [12:0]                      | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
- **MBR (Word 0, bits 15:0)**: Full 16-bit Spanning Member Portmask.
- **MSTI (Word 1, bits 15:12)**: MSTP Spanning Tree Index.
- **FID (Word 1, bits 11:0)**: Forwarding Database ID (SVL/IVL mapping).
- **LUR (Word 2, bit 14)**: L2 Lookup learning bypass flag (`lurep`).
- **METERIDX (Word 2, bits 13:6)**: Traffic Limiter Meter index.
- **POL (Word 2, bit 5)**: VLAN Egress Priority Remarking configuration (`
  envlanpol`).
- **VBPRI (Word 2, bits 4:2)**: Port Priority value.
- **EN (Word 2, bit 1)**: Port-based VLAN Priority override enabled (`vbpen`).
- **EVID (Word 3, bits 12:0)**: Extended 802.1Q VLAN ID.

##### Family B, C, and D - 48-bit Structure (3 Words)

Families B, C, and D only require 48-bits (3 registers) because member masks
are constrained to 11 ports:

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          UNTAG [7:0]          |           MBR [7:0]           | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RS|IS |      METER_LO [4:0]   |POL| VBPRI |EN |   FID [3:0]   | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|               RESERVED                |MH | UNT_E |   MBR_E   | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
- **MBR \[7:0] (Word 0, bits 7:0)**: Lower member ports (0-7).
- **UNTAG \[7:0] (Word 0, bits 15:8)**: Lower untagged ports (0-7).
- **FID \[3:0] (Word 1, bits 3:0)**: VLAN Forwarding ID (scaled down to 4 bits in
  modern configurations).
- **EN (Word 1, bit 4)**: `vbpen`.
- **VBPRI (Word 1, bits 7:5)**: VLAN port priority.
- **POL (Word 1, bit 8)**: `envlanpol`.
- **METER_LO \[4:0] (Word 1, bits 13:9)**: Low bits of traffic Meter index.
- **IS (Word 1, bit 14)**: Independent/Shared Learning configuration flag (`
  IVL_SVL`).
- **MBR_E (Word 2, bits 2:0)**: Extension Member Portmask for ports EXT0, EXT1,
  and EXT2.
- **UNT_E (Word 2, bits 5:3)**: Extension Untagged Portmask for ports EXT0, EXT1,
  and EXT2.
- **MH (Word 2, bit 6)**: High bit of traffic Meter index (`METERIDX_HI`).

#### B. L2 (FDB) Lookup Table Layout Comparison

##### Family A (RTL8370) - 96-bit Structure (6 Words)

- **Port Representation**: Direct 4-bit representation in the FDB entry because
  of the 16-port layout.
- **Struct Bits**:
  - MAC Address: Word 0 to Word 2.
  - Port Field: Mapped inside a clean 4-bit field in Word 4.

##### Family B, C, and D - 96-bit Structure (6 Words)

- **Port Representation**: Split layout (3 bits `PORT` \+ 1 bit `PORT_EXT`) to
  handle the 11-port logical arrangement:
  - **Word 3**: Contains MAC, `VID` \[11:0], `IVL` \[13:13], and `PORT_EXT`
    \[15:15] (EXT port mask).
  - **Word 4**: Contains `EFID`, `FID`, `SA_PRI`, `PORT` \[10:8] (lower 3 bits
    of logical port), `AGE`, `AUTH`, and `SA_BLOCK`.
  - **Word 5**: Contains `DA_BLOCK`, `PRIORITY`, `FWD_PRI`, and `STATIC` status.

### 2.4. L2 Flush Interface (Dynamic Table Purge)

To force the purging (Flush) of dynamically learned MAC addresses.


|Logical Name|Family A (Hex)|Family B (Hex)|Family C (Hex)|Family D (Hex)|Function / Usage|
|-|-|-|-|-|-|
|`L2_FLUSH_PORT_REG`|`0x0A36`|`0x0A36`|`0x0A36`|`0x0A36`|**Bits (7:0):** PORT_MSK. **Bits (15:8):** BUSY. (Ports 0 to 7).|
|`L2_FLUSH_PORT_EXT_REG`|`0x0A35`|`\\\**Not found**`|`0x0A35`|`\\\**Not found**`|**Bits (2:0):** PORT_EXT_MSK. **Bits (5:3):** BUSY. (EXT0 to EXT2).|
|`L2_FLUSH_CTRL1_REG`|`\\\**Not found**`|`0x0A37`|`0x0A37`|`0x0A37`|**Bits (11:0):** VID. **Bits (15:12):** FID. Used in modes below.|
|`L2_FLUSH_CTRL2_REG`|`\\\**Not found**`|`0x0A38`|`0x0A38`|`0x0A38`|**Bits (1:0):** MODE (0=Port, 1=Port+VID). **Bit (2:2):** TYPE (0=Dynamic).|
|`L2_FLUSH_CTRL3_REG`|`\\\**Not found**`|`\\\**Not found**`|`0x0A39`|`0x0A39`|**Bits (0:0):** MSK. Additional global Flush trigger.|

## 3\. Action Plan and Prompts for Iterative Execution

### Step 1: check each section from 1.3 and on using local agent

The web agent is flawled. Section 1.1 and 1.2 are already checked but quota
ended before 1.3 ended.

### Step 2: Integrate Family B and D Bitfield Structs

**Copy and paste the prompt:**

> "Initiate Step 2. Having successfully completed the register validation, we
> must confirm the detailed struct packing for Family B and Family D.
> Double-check if Family B and Family D tables (L2, CVLAN) are completely
> bit-compatible with Family C (48-bit structures), and list any field
> differences."

### Step 3: Handle Advanced Port Isolation and CPU Tagging

**Copy and paste the prompt:**

> "Initiate Step 3. Let's write the C functions for reading/writing CVLAN and
> FDB tables in our driver using conditional branching (Family A vs Family B/C/D)
> based on the table sizing discrepancies we mapped."

