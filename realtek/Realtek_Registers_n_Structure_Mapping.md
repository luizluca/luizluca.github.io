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
rtl8367c_reg.h`, and `rtl8367d_reg.h`).

Some general information about families:
* Ports
  * Family A registers uses ports mask as 0xFFFF, indicanting it can handle up to 16 ports.
  * Families B and D registers uses ports mask as 0xFF, indicanting it can handle up to 8 ports.
  * Family C registers uses ports mask as 0x7FF, indicanting it can handle up to 11 ports.

## 1\. Exhaustive Register Mapping (`rtl8365mb` baseline)

In this section, `p` indicates the logical/physical port index, `e` indicates
the extension port index (EXT0~2), and `msti` indicates the Multiple Spanning
Tree Instance. All registers on the SMI bus are 16-bit wide.

### 1.1. Identification, System, and Interrupts


|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`CHIP_ID_REG`|`0x1300`|`0x1300`|`0x1300`|`0x1300`|Family/Chip ID.|
|`CHIP_VER_REG`|`0x1301`|`0x1301`|`0x1301`|`0x1301`|Silicon version and chip revision.|
|`CHIP_RESET_REG`|`0x1322`|`0x1322`|`0x1322`|`0x1322`|Soft system reset configuration.|
|`MAGIC_REG`|`0x13C2`|`0x13C2`|`0x13C2`|`0x13C2`|Unlock register (required value is `0x0249`).|
|`INTR_POLARITY_REG`|`0x1100`|`0x1100`|`0x1100`|`0x1100`|Configures global IRQ pin polarity and events.|
|`INTR_CTRL_REG`|`0x1101`|`0x1101`|`0x1101`|`0x1101`|Interrupt Mask Register (Interrupt Enable).|
|`INTR_STATUS_REG`|`0x1102`|`0x1102`|`0x1102`|`0x1102`|Interrupt Status Register (Pending Interrupts).|

#### 1.1.1. CHIP_ID_REG (0x1300)

This is a 16-bit read-only register that returns the hardware chip family and
model identifier. The exact value depends on the switch model detected by the
SDK procedures:

* **Family A (RTL8370 / RTL8367):** Returns `0x6088` (for RTL8367R).
* **Family B (RTL8367B):** Returns `0x6000` (for RTL8363SB, RTL8367RB - not checked yet).
* **Family C (RTL8367C / RTL8370B / RTL8365MB / RTL8364B / RTL8363SC_VB):**
  Returns `0x0276`, `0x0597`, or `0x6367` (for RTL8367C, RTL8367S, RTL8367SB,
  RTL8367RB-VB), `0x0652` or `0x6368` (for RTL8370B), or `0x0801` or `0x6511`
  (for RTL8364B or RTL8363SC_VB).
* **Family D (RTL8367D):** Returns `0x6642` (for RTL8367D).

#### 1.1.2. CHIP_VER_REG (0x1301)

This register contains hardware identification subfields. The naming of the
fields changes between older generations (Families A and B) and newer ones
(Families C and D):

##### **Family A, B:**

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

##### **Family C, D:**

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

##### **Family A:**

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

##### **Family B, C, D:**

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

##### **Families A, B, C, and D:** Must be written with the key value `0x0249`
  (represented as `RTL83XX_REG_MAGIC_ID` or `RTL8365MB_MAGIC_VALUE`) to disable
  write protection on certain ASIC registers (such as chip ID and version
  registers) prior to accessing them. Must be written with `0x0000` to re-lock.

#### 1.1.5. INTR_POLARITY_REG (0x1100)

This register configures global interrupt pin polarity and specific sub-system
polarity settings.

##### **Family A:**

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

##### **Family B, C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                                                   RESERVED|POL|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **POL (0:0)**: `INTR_CTRL`. Global IRQ pin polarity. `0` = Active High, `1`
    = Active Low.

##### **Family D:**

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

##### **Family A:**

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

##### **Family B:**

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

##### **Family C:**

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

##### **Family D:**

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

* **Families A, B, C, and D:** The bit layout and names correspond exactly to `INTR_CTRL_REG` (0x1101) for each respective family. A bit set to `1` indicates that the corresponding event is active/pending. Writing `1` to a bit clears that event's pending status. Description of the events matches `INTR_CTRL_REG` (0x1101).

### 1.2. Port Control, MAC and Isolation


|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`PORT_ISOLATION_REG(p)`|`0x08A2 + p`|`0x08A2 + p`|`0x08A2 + p`|`0x08A2 + p`|Allowed ports matrix (`PORT_ISOLATION_PORTx_MASK` in SDK).|
|`PORT_LINKDOWN_IND`|`0x1106`|`0x1106`|`0x1106`|`0x1106`|Portmask of Link Down events.|
|`PORT_LINKUP_IND`|`0x1107`|`0x1107`|`0x1107`|`0x1107`|Portmask of Link Up events.|
|`PORT_MISC_CFG_REG(p)`|`0x000E + (p<<5)`|`0x000E + (p<<5)`|`0x000E + (p<<5)`|`0x000E + (p<<5)`|Miscellaneous MAC configs (`PORTx_MISC_CFG` in SDK).|
|`CFG0_MAX_LEN_REG`|`**Not found**`|`**Not found**`|`0x088C`|`0x088C`|Max Frame Length allowed (MTU).|
|`MAX_LENGTH_LIMINT_IPG`|`0x1200`|`0x1200`|`0x1200`|`0x1200`|Legacy Max Frame Length allowed (in steps).|
|`MAX_LEN_CFG`|`**Not found**`|`0x0883`|`0x0883`|`0x0883`|Max Frame Length allowed (in steps), enabled for ports/speeds defined in MAX_LENGTH_CFG.|
|`MAX_LEN_RX_TX`|`**Not found**`|`0x0884`|`0x0884`|`**Not found**`|Port map for 1000 or 10/100 links, enforcing MAX_LEN_CFG.|


#### 1.2.1. PORT_ISOLATION_REG(p) (0x08A2 + p)

This register sets the port isolation mask for port `p`. Packets egressing port `
p` can only be forwarded to ports set in the `PORT_MASK`.

##### **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           PORT_MASK                           |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (15:0)**: 16-bit mask representing allowed destination ports
    (ports 0 to 15).

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RESERVED      |                 PORT_MASK                 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (10:0)**: 11-bit mask representing allowed destination ports
    (ports 0 to 10).

##### **Families B and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |           PORT_MASK           |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (7:0)**: 8-bit mask representing allowed destination ports
    (ports 0 to 7).


#### 1.2.2. PORT_LINKDOWN_IND (0x1106)

This register indicates which ports triggered a link down state transition.

* **Family A:** Uses a 16-bit mask (15:0) corresponding to ports 0 to 15.
* **Family C:** Uses an 11-bit mask (10:0) corresponding to ports 0
  to 10. Bits 15:11 are reserved.
* **Families B and D:** Uses an 8-bit mask (7:0) corresponding to ports 0
  to 7. Bits 15:8 are reserved.

#### 1.2.3. PORT_LINKUP_IND (0x1107)

This register indicates which ports triggered a link up state transition.

* **Family A:** Uses a 16-bit mask (15:0) corresponding to ports 0 to 15.
* **Family C:** Uses an 11-bit mask (10:0) corresponding to ports 0
  to 10. Bits 15:11 are reserved.
* **Families B and D:** Uses an 8-bit mask (7:0) corresponding to ports 0
  to 7. Bits 15:8 are reserved.

#### 1.2.4. PORT_MISC_CFG_REG(p) (0x000E + (p\<<5))

This register configures various MAC and flow control features per port `p`.

##### **Family A:**

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

##### **Family B, C:**

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

##### **Family D:**

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

This register defines the system-wide maximum frame length (MTU) allowed.

* **Families A and B:** Not supported at this specific address (Family A and B
  SDKs use `MAX_LENGTH_LIMINT_IPG` register, which sets the maximum frame in fixed steps.
* **Families C, D:** Uses a 14-bit mask `CFG0_MAX_LEN_MASK` (`0x3FFF`) to define the maximum frame length in bytes (up to 16383 bytes). There is also additional registers like `MAX_LEN_RX_TX_CFG0(0x088c)` and `MAX_LEN_RX_TX_CFG1(0x088d)` that are current unused in rtl8365mb but may play a similar role.


#### 1.2.6. MAX_LENGTH_LIMINT_IPG (0x1200)

This register configures the legacy maximum frame length, inter-packet gap
(IPG) limits, and flow control thresholds. The layout changes slightly from
Family A to the newer families. In some jam tables, this field is explicitly
written to maximum suppported frame size, delegating the limit to other
registers. The MAX_LEN was dropped in Family D.

##### **Family A:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|PKT| MAX_LEN   |   EGSFC_SHARE_PKT_THR     |CHK|   LIMIT_IPG   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* PKT (15:15): PTKGEN_LENGTH_FIELD_SEL. Packet generator length field selector.
* MAX_LEN (14:13): MAX_LENTH_CTRL. Legacy Max Frame Length control (usually 0 = 1522 bytes, 1 = 1536 bytes, 2 = 1552 bytes, 3 = 16000 bytes).
* EGSFC_SHARE_PKT_THR (12:6): EGSFC_SHARE_PKT_THRESHOLD. Egress flow control share packet threshold.
* CHK (5:5): CHECK_MIN_IPG_RXDV. Check minimum IPG based on RXDV.
* LIMIT_IPG (4:0): LIMIT_IPG_CFG. Inter-packet gap limit configuration.

##### **Families B, C:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV| MAX_LEN   |   PAGES_BEFORE_FCDROP     |CHK|   LIMIT_IPG   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* MAX_LEN (14:13): MAX_LENTH_CTRL. Legacy Max Frame Length control.
* PAGES_BEFORE_FCDROP (12:6): PAGES_BEFORE_FCDROP. Threshold in pages before dropping packets during flow control.
* CHK (5:5): CHECK_MIN_IPG_RXDV. Check minimum IPG based on RXDV.
* LIMIT_IPG (4:0): LIMIT_IPG_CFG. Inter-packet gap limit configuration.

##### **Family D:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED    |   EGSFC_SHARE_PKT_THR     |CHK|   LIMIT_IPG   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* EGSFC_SHARE_PKT_THR (12:6): EGSFC_SHARE_PKT_THRESHOLD. Egress flow control share packet threshold.
* CHK (5:5): CHECK_MIN_IPG_RXDV. Check minimum IPG based on RXDV.
* LIMIT_IPG (4:0): LIMIT_IPG_CFG. Inter-packet gap limit configuration.

#### 1.2.7. MAX_LEN_CFG (0x0883)
This register defines the application of maximum frame length settings based on port speeds.

Families B, C, D: Uses a 2-bit mask MAX_LEN_CFG_MASK (0x3). This determines if the maximum length limit is enforced differently based on the port's link speed (e.g., distinguishing behavior between 10/100Mbps and 1000Mbps links). Not supported on Family A.

#### 1.2.8. MAX_LEN_RX_TX (0x0884)
This register controls whether the maximum frame length limits are applied to the RX or TX paths.

Families B, C: Uses a 2-bit mask MAX_LEN_RX_TX_MASK (0x3) to independently enable or disable the frame length limit validation for ingress (RX) and egress (TX) directions. Not supported on Family A and Family D.

### 1.3. Extension Ports (EXT0, EXT1, EXT2)

|Logical Name|Family A|Family B|Family C|Family D|Function / Usage|
|-|-|-|-|-|-|
|`DIGITAL_IF_SELECT(EXT0/1)`|`0x1305`|`0x1305`|`0x1305`|`0x1305`|EXT0 and EXT1 MAC Interface Mode selectors.|
|`DIGITAL_IF_SELECT(EXT2)`|`**N/A**`|`0x13C3`|`0x13C3`|`0x13C3`|EXT2 MAC Interface Mode selector.|
|`DIGITAL_IF_FORCE(EXT0)`|`0x1310`|`0x1310`|`0x1310`|`**N/A**`|EXT0 Link Force mode and parameters.|
|`DIGITAL_IF_FORCE(EXT1)`|`0x1311`|`0x1311`|`0x1311`|`**N/A**`|EXT1 Link Force mode and parameters.|
|`DIGITAL_IF_FORCE(EXT2)`|`**N/A**`|`0x13C4`|`0x13C4`|`**N/A**`|Link Force mode and parameters.|
|`MACx_FORCE_SELECT_EN`|`**N/A**`|`**N/A**`|`**N/A**`|`0x12C8+(x)`|Link Force mode for MAC x.|
|`EXT_RGMXF_REG(EXT0)`|`0x1306`|`0x1306`|`0x1306`|`0x1306`|EXT0 RGMII TX/RX clock delay and inversion.|
|`EXT_RGMXF_REG(EXT1)`|`0x1307`|`0x1307`|`0x1307`|`0x1307`|EXT1 RGMII TX/RX clock delay and inversion.|
|`EXT_RGMXF_REG(EXT2)`|`**N/A**`|`0x13C5`|`0x13C5`|`0x13C5`|EXT2 RGMII TX/RX clock delay and inversion.|
|`MISC_CFG0_REG`|`**Not found**`|`**Not found**`|`0x130C`|`**Not found**`|Miscellaneous config (DW8051 enable).|
|`BYPASS_LINE_RATE_REG`|`**Not found**`|`**Not found**`|`0x03F7`|`**Not found**`|Line rate bypass portmask.|
|`SDS_OPTION_ARM_REG`|`**Not found**`|`**Not found**`|`0x13C0`|`**Not found**`|Arming for SerDes option read.|
|`SDS_OPTION_REG`|`**Not found**`|`**Not found**`|`0x13C1`|`**Not found**`|SerDes tuning variant selector.|
|`SDS_INDACS_CMD_REG`|`**Not found**`|`**Not found**`|`0x6600`|`**Not found**`|SerDes indirect access command.|
|`SDS_INDACS_ADR_REG`|`**Not found**`|`**Not found**`|`0x6601`|`**Not found**`|SerDes indirect access address.|
|`SDS_INDACS_DATA_REG`|`**Not found**`|`**Not found**`|`0x6602`|`**Not found**`|SerDes indirect access data.|
|`SDS_MISC_REG`|`**Not found**`|`**Not found**`|`0x1D11`|`**Not found**`|SerDes miscellaneous config.|
|`ING_P6_RATE_CTRL0`|`**Not found**`|`**Not found**`|`0x00CF`|`**Not found**`|Port 6 Ingress rate limit LSB.|
|`ING_P6_RATE_CTRL1`|`**Not found**`|`**Not found**`|`0x00D0`|`**Not found**`|Port 6 Ingress rate limit MSB.|
|`EGR_P6_RATE_CTRL0`|`**Not found**`|`**Not found**`|`0x0398`|`**Not found**`|Port 6 Egress rate limit LSB.|
|`EGR_P6_RATE_CTRL1`|`**Not found**`|`**Not found**`|`0x0399`|`**Not found**`|Port 6 Egress rate limit MSB.|


#### 1.3.1. DIGITAL_IF_SELECT(EXT0/1) (0x1305)

This register selects the MAC interface mode for EXT0 and EXT1 ports.

##### **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|COL|CRS|SK1|SK0|   RESERVED    |DM0|  EXT1_SEL |DM1| EXT0_SEL  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **COL (15:15)**: `ORG_COL`. Original Collision signal behavior configuration.
  * **CRS (14:14)**: `ORG_CRS`. Original Carrier Sense signal behavior.
  * **SK1 (13:13)**: `SKIP_MII_1_RXER`. Ignore RXER signal from EXT1 port.
  * **SK0 (12:12)**: `SKIP_MII_0_RXER`. Ignore RXER signal from EXT0 port.
  * **DM0 (7:7)**: `SELECT_DUMMY_0`. Unknown.
  * **EXT1_SEL (6:4)**: `SELECT_RGMII_1`. 3-bit interface mode for EXT1 (see mode
    table below)
  * **DM1 (3:3)**: `SELECT_DUMMY_1`. Unknown.
  * **EXT0_SEL (2:0)**: `SELECT_RGMII_0`. 3-bit interface mode for EXT0 (see mode
    table below).

##### **Families B, C, and D:**

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

##### **Families B, C, and D:**

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
  * **All Families:**
    - `0` – `DISABLE` – Port disabled
    - `1` – `RGMII` – Reduced Gigabit MII
    - `2` – `MII_MAC` – MII in MAC mode
    - `3` – `MII_PHY` – MII in PHY mode
    - `4` – `TMII_MAC` – Turbo‑MII in MAC mode
    - `5` – `TMII_PHY` – Turbo‑MII in PHY mode
    - `6` – `GMII` – Gigabit MII
  * **Family A:**
    - `7` – `RGMII_33V` – Reduced Gigabit MII using 3.3V
  * **Families B, C and D:**
    - `7` – `RMII_MAC` – Reduced MII in MAC mode
    - `8` – `RMII_PHY` – Reduced MII in PHY mode
  * **Families C and D:**
    - `9` – `SGMII` – Serial‑Gigabit MII (SerDes)
    - `10` – `HSGMII` – High‑speed SGMII (2.5 G SerDes)
    - `11` – `1000X_100FX` – SFP auto‑detect (1000Base‑X or 100Base‑FX)
    - `12` – `1000X` – SFP 1000Base‑X only
    - `13` – `100FX` – SFP 100Base‑FX only

#### 1.3.3. DIGITAL_IF_FORCE(EXTx) (0x1310 / 0x1311 / 0x13C4)

This register forces the link parameters for an extension port when force mode
is active. Family D uses MACx_FORCE_SELECT_EN (0x12C8+x)

##### **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|  RESERVED |EN |L1K|L10|MSF|MSM|NWY|TXP|RXP|LNK|RSV|DPX|  SPD  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **EN (12:12)**: forcemode / GMII_x_FORCE (0x1000). Enable Force Mode. 1 = force link parameters, 0 = auto-negotiation.
  * **L1K (11:11)**: lpi1000. Force 1000Mbps EEE Low Power Idle capability.
  * **L10 (10:10)**: lpi100. Force 100Mbps EEE Low Power Idle capability.
  * **MSF (9:9)**: mstfault. Force Master/Slave fault flag.
  * **MSM (8:8)**: mstmode. Force Master/Slave mode configuration.
  * **NWY (7:7)**: nway. Force NWAY. MAC-side Auto-negotiation advertisement enable.
  * **TXP (6:6)**: txpause. Force TX Pause advertisement status.
  * **RXP (5:5)**: rxpause. Force RX Pause advertisement status.
  * **LNK (4:4)**: link. Force Link state. 1 = Force Link UP.
  * **RSV (3:3)**: reserve1. Reserved bit.
  * **DPX (2:2)**: duplex. Force Duplex state.
    * `1` = Full Duplex
    * `0` = Half Duplex
  * **SPD (1:0)**: speed. Force Speed rate.
    * `0` = 10 Mbps
    * `1` = 100 Mbps
    * `2` = 1000 Mbps
    * `3` = Reserved

##### **Families B and C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|  RESERVED |EN |RSERVED|MSF|MSM|NWY|TXP|RXP|LNK|RSV|DPX|  SPD  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **EN (12:12)**: `GMII_x_FORCE` (`0x1000`). Enable Force Mode. `1` = force
    link parameters, `0` = auto-negotiation.
  * **MSF (9:9)**: mstfault. Force Master/Slave fault flag.
  * **MSM (8:8)**: mstmode. Force Master/Slave mode configuration.
  * **NWY (7:7)**: Force NWAY. MAC-side Auto-negotiation advertisement enable.
  * **TXP (6:6)**: Force TX Pause advertisement.
  * **RXP (5:5)**: Force RX Pause advertisement.
  * **LNK (4:4)**: Force Link state. `1` = Force Link UP.
  * **DPX (2:2)**: Force Duplex.
    * `1` = Full Duplex
    * `0` = Half Duplex
  * **SPD (1:0)**: Force Speed.
    * `0` = 10 Mbps
    * `1` = 100 Mbps
    * `2` = 1000 Mbps
    * `3` = 2500 Mbps (only Family C)

#### 1.3.4. MACx_FORCE_SELECT_EN (0x12C8+x)

This register configures the link override (Link Force) parameters individually per logical MAC port in Family D switches. While legacy hardware generations (Families A, B, and C) centralize extension port forcing within a unified DIGITAL_IF_FORCE(EXTx) register layout, the Family D architecture distributes this mechanism across individual MAC forcing registers, offering an extended bitfield array to independently force and enable abilities on a granular level.

##### **Family D:**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|SPD_HI |L1K|L10|MSF|MSM|NWY|TXP|RXP|LNK|F1G|DPX|SPD_LO |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **SPD_HI (13:12)**: FORCE_SPEED[23]_ABLTY (0x1000). Forces the highest speed bit on interfaces.
* **L1K (11:11)**: FORCE_LPI_1000_ABLTY (0x0800). Forces Energy-Efficient Ethernet (EEE) Low Power Idle (LPI) state capabilities when the port is operating at 1000 Mbps.
* **L10 (10:10)**: FORCE_LPI_100_ABLTY (0x0400). Forces Energy-Efficient Ethernet (EEE) Low Power Idle (LPI) state capabilities when the port is operating at 100 Mbps.
* **MSF (9:9)**: FORCE_MST_FAULT_ABLTY (0x0200). Forces the detection and signaling of Master/Slave auto-negotiation faults.
* **MSM (8:8)**: FORCE_MST_MOD_ABLTY (0x0100). Forces manual Master/Slave mode selection on the physical layer interface.
* **NWY (7:7)**: FORCE_NWAY_ABLTY (0x0080). Forces the activation or advertisement of NWAY-based auto-negotiation.
* **TXP (6:6)**: FORCE_TXPAUSE_ABLTY (0x0040). Forces the transmission capability of flow control pause frames (TX Pause) for symmetric or asymmetric configurations.
* **RXP (5:5)**: FORCE_RXPAUSE_ABLTY (0x0020). Forces the reception and processing capability of incoming link-partner pause frames (RX Pause).
* **LNK (4:4)**: FORCE_LINK_ABLTY (0x0010). Forces the port's logical link state, completely overriding the physical transceiver signaling (1 = Force stable Link UP).
* **F1G (3:3)**: FORCE_FIB1G_ABLTY (0x0008). Forces the specific synchronization and sub-layer operation parameters for SerDes transceivers locked into 1000Base-X Fiber mode.
* **DPX (2:2)**: FORCE_DUPLEX_ABLTY (0x0004). Forces the duplex state of the port MAC.
  * `1` = Full Duplex
  * `0` = Half Duplex
* **SPD_LO (1:0)**: Forces the lowest speed bit on interfaces. Combined field matching SPD_HI and SPD_LO to define the base link speed:
  * `0` = 10 Mbps
  * `1` = 100 Mbps
  * `2` = 1000 Mbps
  * `3` = 500 Mbps
  * `4` = Reserved
  * `5` = 2500 Mbps
  * `6` = Reserved
  * `7` = Reserved

#### 1.3.5. EXT_RGMXF_REG(EXTx) (0x1306 / 0x1307 / 0x13C5)

This register configures RGMII TX/RX clock delay and optional clock inversion
per extension port.

##### **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                   RESERVED                    |TXD|    RXD    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **TXD (3:3)**: `TXDELAY`. TX delay configuration (1-bit). Controls internal TX clock  delay taps.
    * `0` = 0 ns
    * `1` = 2 ns
  * **RXD (2:0)**: `RXDELAY`. 3-bit RX clock delay stages (~0.3 ns).
    * `0` = 0 ns
    * `1` = 0.3 ns
    * `2` = 0.6 ns
    * `3` = 0.9 ns
    * `4` = 1.2 ns
    * `5` = 1.5 ns
    * `6` = 1.8 ns
    * `7` = 2.1 ns

##### **Families B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                   RESERVED        |TXI|RXI|RSV|TXD|    RXD    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **TXI (6:6)**: `RGTX_INV`. Invert RGMII TX clock polarity.
  * **RXI (5:5)**: `RGRX_INV`. Invert RGMII RX clock polarity.
  * **TXD (3:3)**: `TXDELAY`. TX delay configuration (1-bit). Controls internal TX clock  delay taps.
    * `0` = 0 ns
    * `1` = 2 ns
  * **RXD (2:0)**: `RXDELAY`. 3-bit RX clock delay stages (~0.3 ns).
    * `0` = 0 ns
    * `1` = 0.3 ns
    * `2` = 0.6 ns
    * `3` = 0.9 ns
    * `4` = 1.2 ns
    * `5` = 1.5 ns
    * `6` = 1.8 ns
    * `7` = 2.1 ns

#### 1.3.6. MISC_CFG0_REG (0x130C)

This register contains miscellaneous system-wide configuration bits for various
internal controllers and features.

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|ADP|ADE|FLS|EEE|NIC| FT|OLT|RTC|PON|805|AUT|NRS|PTI|BST|EFU|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **ADP (14:14)**: `ADCCKI_FROM_PAD`. ADC clock source selection (1=Pad).
  * **ADE (13:13)**: `ADCCKI_EN`. ADC clock enable.
  * **FLS (12:12)**: `FLASH_ENABLE`. Internal/External Flash interface enable.
  * **EEE (11:11)**: `EEE_ENABLE`. Energy Efficient Ethernet global enable.
  * **NIC (10:10)**: `NIC_ENABLE`. Network Interface Controller enable.
  * **FT  (9:9)**: `FT_ENABLE`. Fault Tolerance feature enable.
  * **OLT (8:8)**: `OLT_ENABLE`. Optical Line Terminal (PON) logic enable.
  * **RTC (7:7)**: `RTCT_EN`. Real-Time Cable Diagnosis enable.
  * **PON (6:6)**: `PON_LIGHT_EN`. PON Light-sleep/power-saving enable.
  * **805 (5:5)**: `DW8051_EN`. Enable the embedded DW8051 MCU.
  * **AUT (4:4)**: `AUTOLOAD_EN`. EEPROM/Efuse autoload enable.
  * **NRS (3:3)**: `NRESTORE_EN`. Network restore (backup) logic enable.
  * **PTI (2:2)**: `DIS_PON_TABLE_INIT`. Disable PON table auto-initialization.
  * **BST (1:1)**: `DIS_PON_BIST`. Disable PON Built-In Self Test.
  * **EFU (0:0)**: `EFUSE_EN`. Efuse controller enable.


#### 1.3.7. BYPASS_LINE_RATE_REG (0x03F7)

This register allows bypassing the line rate constraints (scheduler) for
external ports.

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|               RESERVED                |P10| P9| P8| P7| P6| P5|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **P10 (5:5)**: `BYPASS_PORT10_CONSTRAINT`. Bypasses scheduler for Port 10.
  * **P9  (4:4)**: `BYPASS_PORT9_CONSTRAINT`. Bypasses scheduler for Port 9.
  * **P8  (3:3)**: `BYPASS_PORT8_CONSTRAINT`. Bypasses scheduler for Port 8.
  * **P7  (2:2)**: `BYPASS_PORT7_CONSTRAINT`. Bypasses scheduler for Port 7.
  * **P6  (1:1)**: `BYPASS_PORT6_CONSTRAINT`. Bypasses scheduler for Port 6.
  * **P5  (0:0)**: `BYPASS_PORT5_CONSTRAINT`. Bypasses scheduler for Port 5.

#### 1.3.8. SDS_OPTION_ARM_REG (0x13C0) / SDS_OPTION_REG (0x13C1)

These registers are used to probe the SerDes tuning parameter variant (chip
option).

##### **Family C:**
  * **SDS_OPTION_ARM_REG (0x13C0)**: `RTL8367C_REG_PROTECT_ID`. Arming register.
    Write magic key `0x0249` to arm the option read, and `0x0000` to disarm.
  * **SDS_OPTION_REG (0x13C1)**: `RTL8367C_REG_CHIP_VER_INTL`.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                   RESERVED                    |    OPTION     |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **OPTION (3:0)**: `CHIP_VER_INTL`. Internal chip version/variant selector
    used to pick SerDes tuning parameters.

#### 1.3.9. SerDes Indirect Access (SDS_INDACS) (0x6600-0x6602)

Registers used for indirect access to the internal SerDes PHY registers.

##### **Family C:**

**SDS_INDACS_CMD_REG (0x6600):**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED        |BSY|RUN|WR |          IDX          |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **BSY (8:8)**: `SDS_CMD_BUSY`. Indirect access engine busy.
  * **RUN (7:7)**: `SDS_CMD`. Execute the command.
  * **WR (6:6)**: `SDS_RWOP`. Operation type (1=Write, 0=Read).
  * **IDX (5:0)**: `SDS_INDEX`. Internal SerDes instance index.

**SDS_INDACS_ADR_REG (0x6601):**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|       RESERVED    |         PAGE          |       RAD         |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PAGE (10:5)**: `SDS_PAGE`. Internal SerDes register page (6-bit).
  * **RAD (4:0)**: `SDS_REGAD`. Internal SerDes register address within page
    (5-bit). Combined with PAGE, it forms an 11-bit internal address.

* **SDS_INDACS_DATA_REG (0x6602)**: 16-bit data to write or read result.

**Common SerDes Internal Registers:**
  * `0x0000`: `BMCR`. Basic Mode Control Register.
  * `0x0002`: `NWAY`. Autonegotiation configuration.
  * `0x0003`: `RESET`. SerDes data path reset control.
  * `0x003d`: `LINK_STATUS`. Internal SerDes link status.

#### 1.3.10. SerDes Miscellaneous Configuration (SDS_MISC) (0x1D11)

This register provides direct control over the SerDes mux and forced link
parameters for the HSGMII/SGMII CPU port.

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|RXF|TXF|ARB|HSG|FDP|LNK|  SPD  |SGM|  INB_SEL  |  SDS_MODE |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **RXF (14:14)**: `SGMII_RXFC`. SGMII RX Flow Control enable.
  * **TXF (13:13)**: `SGMII_TXFC`. SGMII TX Flow Control enable.
  * **ARB (12:12)**: `INB_ARB`. In-band arbitration enable.
  * **HSG (11:11)**: `MAC8_SEL_HSGMII`. Select HSGMII mode for SerDes-to-MAC8 mux.
  * **FDP (10:10)**: `SGMII_FDUP`. Force Full Duplex on SerDes link.
  * **LNK (9:9)**: `SGMII_LINK`. Force Link UP on SerDes.
  * **SPD (8:7)**: `SGMII_SPD`. Force Speed on SerDes link.
    * `0` = 10 Mbps
    * `1` = 100 Mbps
    * `2` = 1000 Mbps (also used for 2.5 Gbps mode).
  * **SGM (6:6)**: `MAC8_SEL_SGMII`. Select SGMII mode for SerDes-to-MAC8 mux.
  * **INB_SEL (5:3)**: `INB_SEL`. In-band selection source for link parameters.
    * `0` = Force mode (uses bits 10:7).
    * `1` = SGMII In-band AN.
    * `2` = Fiber In-band AN.
  * **SDS_MODE (2:0)**: `SDS_MODE_18C`. SerDes protocol mode.
    * `0` = SGMII
    * `4` = 1000Base-X
    * `5` = 100Base-FX
    * `7` = Auto-detect (1000Base-X / 100Base-FX)

#### 1.3.11. Port 6 Rate Control (0x00CF-0x00D0, 0x0398-0x0399)

Bandwidth rate limiters specifically for Port 6. Limits are 19-bit values in
units of 8 Kbps.

##### **Family C:**

**CTRL0 (LSB):**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RATE_LSB                            |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **RATE_LSB (15:0)**: `INGRESSBW_RATE15_0` / `EGRESSBW_RATE15_0`. Lower 16
    bits of the rate limit.

**CTRL1 (MSB):**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                     RESERVED                      |  RATE_MS  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **RATE_MSB (2:0)**: `INGRESSBW_RATE18_16` / `EGRESSBW_RATE18_16`. Upper 3
    bits of the rate limit.

### 1.4. Flooding, MSTI, and CPU Port


|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`MSTI_CTRL_REG(msti, p)`|`0x0A00 + (msti * 2) + (p/8)`|`0x0A00 + (msti * 2)`|`0x0A00 + (msti * 2) + (p/8)`|`0x0A00 + (msti * 2)`|Multiple Spanning Tree Instance state per port.|
|`UNKNOWN_UC_FLOOD`|`0x0890`|`0x0890`|`0x0890`|`0x0890`|Portmask for unknown Unicast flooding destination.|
|`UNKNOWN_MC_FLOOD`|`0x0891`|`0x0891`|`0x0891`|`0x0891`|Portmask for unknown Multicast flooding destination.|
|`UNKNOWN_BC_FLOOD`|`0x0892`|`0x0892`|`0x0892`|`0x0892`|Portmask for Broadcast flooding destination.|
|`CPU_PORT_MASK_REG`|`0x1219`|`0x1219`|`0x1219`|`0x1219`|CPU Port Mask configuration.|
|`CPU_CTRL_REG`|`0x121A`|`0x121A`|`0x121A`|`0x121A`|CPU Tag insertion/removal and Trap port control.|


#### 1.4.1. MSTI_CTRL_REG(msti, p) (0x0A00 + (msti * 2) + (p/8))

Each 16-bit register packs STP state for 8 ports (2 bits each). The register
address encodes the MSTI index and port group.

##### **Families A, B, C, and D:**

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
  * *Note*: Family B and D ports fits in a single 16-bit register. However, Realtek reserved
  2 register per MSTI anyway and the expression 0x0A00+(msti * 2)+(p/8) is still valid for all families.

#### 1.4.2. UNKNOWN_UC_FLOOD / UNKNOWN_MC_FLOOD / UNKNOWN_BC_FLOOD (0x0890 / 0x0891 / 0x0892)

These three registers define the flooding portmask for their respective traffic
class.

* **Family A:** Uses a 16-bit mask (15:0) for ports 0 to 15.
* **Families B and D:** Uses an 8-bit mask (7:0) for ports 0 to 7. Bits 15:8 are
  reserved.
* **Family C:** Uses an 11-bit mask (10:0) for ports 0 to 10. Bits
  15:11 are reserved.

#### 1.4.3. CPU_PORT_MASK_REG (0x1219)

This register defines which ports are considered CPU ports for CPU tag
processing.

* **Family A:** Uses a 16-bit mask (15:0) for ports 0 to 15.
* **Families B and D:** Uses an 8-bit mask (7:0) for ports 0 to 7. Bits 15:8 are
  reserved.
* **Family C:** Uses an 11-bit mask (10:0) for ports 0 to 10. Bits
  15:11 are reserved.

#### 1.4.4. CPU_CTRL_REG (0x121A)

This register controls CPU tag insertion, removal, and the trap port
destination.


##### **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|       RESERVED            |DRP|BYP|   TRAP_PORT   |INSMODE|EN |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **DRP (8:8)**: `IOL_16DROP_MASK`. Inter-packet block/drop configuration rules.
* **BYP (7:7)**: `BYPASS_INQUEUE_MASK`. Direct ingress queue validation bypass configuration.
* **TRAP_PORT (6:3)**: `TRAP_PORT_MASK`. A 4-bit field indexing the system trap port (required to choose among ports 0–15).
* **INSMODE (2:1)**: `INSERTMODE_MASK`. CPU tag injection properties.
  * `0` = Insert into all CPU egress frames.
  * `1` = Insert into Trapped/Redirected frames only.
  * `2` = Disabled CPU tag insertion.
  * `3` = Reserved.
* **EN (0:0)**: `EN_MASK`. Activates the CPU engine subsystem.

##### **Family B:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          RESERVED     |FMT|DRP|RXC|POS| TRAP_PORT |INSMODE|EN |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **FMT (9:9)**: `TAG_FORMAT_MASK`. Selects the structure format of the Realtek tag layout.
  * `0` = 8-byte format.
  * `1` = 4-byte format.
* **DROP (8:8)**: `IOL_16DROP_MASK`. Inter-packet drop flag.
* **RXC (7:7)**: `TAG_RXBYTECOUNT_MASK`. Instructs hardware to append paged frame-size metadata.
* **POS (6:6)**: `TAG_POSITION`. Insertion position:
  * `0` = After SA (standard).
  * `1` = Prefix (before DA).
* **TRAP_PORT (5:3)**: `TRAP_PORT_MASK`. A down-scaled 3-bit field indexing trap destinations (sufficient for ports 0–7).
* **INSMODE (2:1)**: `INSERTMODE_MASK`. Tag insertion policy modes.
  * `0` = Insert into all CPU egress frames.
  * `1` = Insert into Trapped/Redirected frames only.
  * `2` = Disabled CPU tag insertion.
  * `3` = Reserved.
* **EN (0:0)**: `EN_MASK`. Global CPU tagging engine activation.

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RESERVED      |THI|FMT|DRP|RXC|POS| TRAP_PORT |INSMODE|EN |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **THI (10:10)**: `TRAP_PORT_EXT`. Trap port high 1-bit.
* **FMT (9:9)**: `TAG_FORMAT`. Defines Realtek CPU Tag structure format.
  * `0` = 8-byte format.
  * `1` = 4-byte format.
* **DROP (8:8)**: `IOL_16DROP_MASK`. Inter-packet drop flag.
* **RXC (7:7)**: `RXBYTECOUNT`. Append RX frame length metadata in CPU tags.
* **POS (6:6)**: `TAG_POSITION`. Insertion position:
  * `0` = After SA (standard).
  * `1` = Prefix (before DA).
* **TRAP_PORT (5:3)**: lower 3-bit logical port ID directing where trapped/redirected
  system traffic is sent. Must be used with THI.
* **INSMODE (2:1)**: `INSERTMODE`. Tag insertion policy modes.
  * `0` = Insert into all CPU egress frames.
  * `1` = Insert into Trapped/Redirected frames only.
  * `2` = Disabled CPU tag insertion.
  * `3` = Reserved.
* **EN (0:0)**: `ENABLE`. Global activation of Realtek CPU Tag processing.

##### **Family D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                   |PRI|FMT|DRP|RXC|POS| TRAP_PORT |INSMODE|EN |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **PRI (10:10)**: `TAG_FORMAT_PRI_MASK`. Enforces dedicated priority assignment rules within the Family D modified CPU tag template.
* **FMT (9:9)**: `TAG_FORMAT`. Defines Realtek CPU Tag structure format.
  * `0` = 8-byte format.
  * `1` = 4-byte format.
* **DROP (8:8)**: `IOL_16DROP_MASK`. Inter-packet drop flag.
* **RXC (7:7)**: `RXBYTECOUNT`. Append RX frame length metadata in CPU tags.
* **POS (6:6)**: `TAG_POSITION`. Insertion position:
  * `0` = After SA (standard).
  * `1` = Prefix (before DA).
* **TRAP_PORT (5:3)**: lower 3-bit logical port ID directing where trapped/redirected
  system traffic is sent.
* **INSMODE (2:1)**: `INSERTMODE`. Tag insertion policy modes.
  * `0` = Insert into all CPU egress frames.
  * `1` = Insert into Trapped/Redirected frames only.
  * `2` = Disabled CPU tag insertion.
  * `3` = Reserved.
* **EN (0:0)**: `ENABLE`. Global activation of Realtek CPU Tag processing.


### 1.5. VLAN Configurations


|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`VLAN_CTRL_REG`|`0x07A8`|`0x07A8`|`0x07A8`|`0x07A8`|Global VLAN support activation (bit 0 = enable).|
|`VLAN_PVID_CTRL_REG(p)`|`0x0700 + (p/2)`|`0x0700 + (p/2)`|`0x0700 + (p/2)`|`**Not found**`|Port Default VID/PVID VLAN MC index (2 ports per register).|
|`VLAN_PVID_CTRL0(p)`|`**Not found**`|`**Not found**`|`**Not found**`|`0x0700 + p`|Port Default VID/PVID Number.|
|`VLAN_ACCEPT_FRAME(p)`|`0x07AA + (p/8)`|`0x07AA`|`0x07AA + (p/8)`|`0x07AA`|Accept Frame Type rules (Tagged/Untagged) per port.|
|`VLAN_INGRESS_REG`|`0x07A9`|`0x07A9`|`0x07A9`|`0x07A9`|Ingress filtering activation portmask.|
|`VLAN_EGRESS_TRANS_REG(p)`|`**Not found**`|`**Not found**`|`0x09D0 + p`|`0x09D0 + p`|Egress VLAN transparency mapping per port.|
|`PORT_EFID_REG(p)`|`0x0A32 + (p/4)`|`0x0A32 + (p/4)`|`0x0A32 + (p/4)`|`**Not found**`|Enhanced Filtering Database ID (EFID) mapping.|
|`VLAN_MC(i)`|`0x0728 + (i * 4)`|`0x0728 + (i * 3)`|`0x0728 + (i * 3)`|`**Not found**`|VLAN member config entries 0~31.|

#### 1.5.1. VLAN_CTRL_REG (0x07A8)

This register globally enables the VLAN subsystem.

##### **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                  RESERVED                                 |EN |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **EN (0:0)**: `ENABLE`. Global activation of VLAN filtering.

#### 1.5.2. VLAN_PVID_CTRL_REG(p) (0x0700 + (p/2))

Each register encodes the VLAN MC index for two ports.
That VLAN MC entry will determine what is the VID number user as PVID. Check
VLAN_MC(i).

***Note:*** Family D dropped VLAN MC and used `VLAN_PVID_CTRL0(p)` as a way to
directly inform the PVID VID number.

##### **Families A, B, and C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  | PVID_IDX_PORT_N+1 | RESERVED  |  PVID_IDX_PORT_N  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **EPVID_IDX_PORT_N+1 (12:8)**: VLAN MC index that is used as PVID for port N+1.
* **EPVID_IDX_PORT_N (4:0)**: VLAN MC index that is used as PVID for port N.

#### 1.5.3. VLAN_PVID_CTRL0(p) (0x0700 + p)

Family D dropped VLAN MC completely. The VLAN_PVID_CTRL0(p) now stores the VID number directly, replacing the old VLAN_PVID_CTRL_REG(p) that stores a VLAN MC index.

##### **Family D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |                     PVID_VID                      |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **PVID_VID (12:0)**: VLAN VID number used as PVID for port p (up to 4095).

#### 1.5.4. VLAN_ACCEPT_FRAME(p) (0x07AA + (p/8))

Each register encodes the frame acceptance mode for four ports (2 bits per
port).

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|AF_P+7 |AF_P+6 |AF_P+5 |AF_P+4 |AF_P+3 |AF_P+2 |AF_P+1 |AF_P+0 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **AF_P+(n)**: Accept frame flag for port n+(p%8)
  * `0` = Accept all type of frames.
  * `1` = Accept tagged frames only.
  * `2` = Accept untagged frames only.
  * `3` = Reserved.

#### 1.5.5. VLAN_INGRESS_REG (0x07A9)

This register activates ingress filtering on a per-port basis. Even with
ingress filtering disabled, the packet egress will still only forward to
ports that are member of the packet VLAN (or PVID if not tagged). For egress
port, VLAN_EGRESS_TRANS_REG(p) can be used to forward to a port independently
from the VLAN memberships.

##### **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           PORT_MASK                           |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (15:0)**: 16-bit mask representing ingress filtering for ports
    (ports 0 to 15).

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RESERVED      |                 PORT_MASK                 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (10:0)**: 11-bit mask representing ingress filtering for ports
    (ports 0 to 10).

##### **Families B and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |           PORT_MASK           |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (7:0)**: 8-bit mask representing ingress filtering for ports
    (ports 0 to 7).

#### 1.5.6. VLAN_EGRESS_TRANS_REG(p) (0x09D0 + p)

Configure transparent VLAN forwarding, independtly from the VLAN membership.
This feature is missing in family A and B.

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RESERVED      |                 PORT_MASK                 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (10:0)**: 11-bit mask representing egress ports
    (ports 0 to 10) to which traffic from port p should be forwarded,
    independently from VLAN membership.

##### **Families B and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |           PORT_MASK           |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **PORT_MASK (7:0)**: 8-bit mask representing egress ports
    (ports 0 to 7) to which traffic from port p should be forwarded,
    independently from VLAN membership.


#### 1.5.7. PORT_EFID_REG(p) (0x0A32 + (p/4))

This register sets the EFID for a specific port. Each family allocates the number of
sequentional register to fit all its ports.
- **Family A**: 0x0A32..0x0A36.
- **Family B**: 0x0A32..0x0A33.
- **Family C**: 0x0A32..0x0A34.

**Note:** Family D reused 0x0A32 as `LUT_CFG2`, which was present in Family C at `0x0a3a`.

TODO: How family D handles it!?

##### **Families A, B and C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|  EFID_P+3 |RSV|  EFID_P+2 |RSV|  EFID_P+1 |RSV|  EFID_P+0 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **EFID_P+(n)**: EFID number (3-bit) used by port n+(p%4).

#### 1.5.8. VLAN_MC(i) A:(0x0728 + (i * 4)) B,C:(0x0728 + (i * 3))

VlanMC is a VLAN database composed of 32 entries (i as the table index). For
Families A, B, and C, it is only used in driver rtl8365mb as a way to inform
the VID for PVID register. For that usage, member is ignored by the switch.

##### **Family A**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                          MEMBER                               | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|      MSTI     |                      FID                      | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|           METERID             |POL|   VBPRI   |EN |REP| Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |                      EVID                         | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```
* **MEMBER (Word 0, bits 15:0)**: Complete port member mask for the VLAN.
* **MSTI (Word 1, bits 15:12)**: `MSTI_MASK (0xF000)` - Multiple Spanning Tree Instance index.
* **FID (Word 1, bits 11:0)**: `FID_MASK (0xFFF)` - VLAN Forwarding ID.
* **METERIDX (Word 2, bits 13:6)**: `METERIDX_MASK (0x3FC0)` - Traffic Meter Index.
* **POL (Word 2, bit 5)**: `ENVLANPOL_MASK (0x20)` - Enable VLAN Policy configuration flag.
* **VBPRI (Word 2, bits 4:2)**: `VBPRI_MASK (0x1C)` - VLAN Port Priority level.
* **EN (Word 2, bit 1)**: `VBPEN_MASK (0x2)` - VLAN-based Priority Enable flag.
* **REP (Word 2, bit 0)**: `LUREP(0x1)` - Lookup Replace?? Replicate?? Replay?? Representation??.
* **EVID (Word 3, bits 12:0)**: `CTRL3_MASK (0x1FFF)` - Enhanced/Extended VLAN ID.


##### **Family B**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |          MEMBER               | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                       RESERVED                |    FID_MSTI   | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED    |     METERIDX      |POL|   VBPRI   |EN | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|  RESERVED |                  EVID                             | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```

* **MEMBER (Word 0, bits 7:0)**: `CTRL0_MASK (0xFF)` - Port member mask for the VLAN.
* **FID_MSTI (Word 1, bits 3:0)**: `CTRL1_MASK (0xF)` - Shared Forwarding ID / Multiple Spanning Tree Instance configuration bits.
* **METERIDX (Word 2, bits 9:5)**: `METERIDX_MASK (0x3E0)` - Traffic Meter Index.
* **POL (Word 2, bit 4)**: `ENVLANPOL_MASK (0x10)` - Enable VLAN Policy configuration flag.
* **VBPRI (Word 2, bits 3:1)**: `VBPRI_MASK (0xE)` - VLAN Port Priority level.
* **EN (Word 2, bit 0)**: `VBPEN_MASK (0x1)` - VLAN-based Priority Enable flag.
* **EVID (Word 3, bits 12:0)**: `CTRL3_MASK (0x1FFF)` - Enhanced/Extended VLAN ID.

##### **Family C**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|        RESERVED   |                  MEMBER                   | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                       RESERVED                |   FID_MSTI    | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED        |        METERIDX       |POL|   VBPRI   |EN | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |                      EVID                         | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```
* **MEMBER (Word 0, bits 10:0)**: `MBR_MASK (0x7FF)` - port member mask for the VLAN.
* **FID_MSTI (Word 1, bits 3:0)**: `CTRL1_MASK (0xF)` - Shared Forwarding ID / Multiple Spanning Tree Instance configuration bits.
* **METERIDX (Word 2, bits 10:5)**: `METERIDX_MASK|METERIDX_EXT_MASK (0xFE0)` - Traffic Meter Index.
* **POL (Word 2, bit 4)**: `ENVLANPOL_MASK (0x10)` - Enable VLAN Policy configuration flag.
* **VBPRI (Word 2, bits 3:1)**: `VBPRI_MASK (0xE)` - VLAN Port Priority level.
* **EN (Word 2, bit 0)**: `VBPEN_MASK (0x1)` - VLAN-based Priority Enable flag.
* **EVID (Word 3, bits 12:0)**: `CTRL3_MASK (0x1FFF)` - Enhanced/Extended VLAN ID.

### 1.6. MAC Learning & Security


|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`LUT_PORT_LEARN_LIMIT(p)`|`0x0A20 + p`|`0x0A20 + p`|`0x0A20 + p`|`0x0A20 + p`|Limits maximum dynamically learned MACs per physical port.|


#### 1.6.1. LUT_PORT_LEARN_LIMIT(p) (0x0A20 + p)

This register defines the maximum number of MAC addresses that can be
dynamically learned on port `p`. Setting as 0 disables learning.

##### **Family A:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|                    NUMBER_OF_ADDRESS                  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **NUMBER_OF_ADDRESS (13:0)**: 14-bit (16383) number representing the
  maximum number of dynamic address to be learned.

##### **Families B and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED    |                NUMBER_OF_ADDRESS              |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **NUMBER_OF_ADDRESS (11:0)**: 12-bit (4095) number representing the
  maximum number of dynamic address to be learned.

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |                    NUMBER_OF_ADDRESS              |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **NUMBER_OF_ADDRESS (12:0)**: 13-bit (8191) number representing the
  maximum number of dynamic address to be learned.

### 1.7. MIB Counters (Statistics)

Polling MIB counters requires first specifying the target port/counter ID and
then retrieving results in a structured multi-register block after results are ready.

|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|-|
|`MIB_ADDRESS_REG`|`0x1004`|`0x1004`|`0x1004`|`0x1004`|Target Port and counter selection for MIB polling.|
|`MIB_CTRL0_REG`|`0x1005`|`0x1005`|`0x1005`|`0x1005`|Poll execution trigger, reset command, and busy flag.|
|`MIB_CTRL1_REG`|`0x1006`|`**Not found**`|`**Not found**`|`**Not found**`|Extra port reset command.|
|`MIB_COUNTER(w)`|`0x1000+w`|`0x1000+w`|`0x1000+w`|`0x1000+w`|Staging register block where the latched counter value resides. It contains 4 words (w in {0..3})|

**MIB Address Calculation:**

- `MIB_Address = (0x007C * port + counter_offset) >> 2`

#### 1.7.1. MIB_ADDRESS_REG (0x1004)

This register define the address of a MIB metric. It is calculated based on the metric order and the port.
Each family has a different number of metrics.
* **Family A**: ((p * 0x50) + metric_offset) / 4.
* **Families B, C and D **: ((p * 0x7C) + metric_offset) / 4.

All current metrics are either 64-bit or 32-bit. Metrics are read at MIB_COUNTER(w), with two 32-bit metrics sharing the same MIB_ADDRESS_REG(w={0,1} and w={2,3}).

##### **Families A, B, C, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          RESERVED         |               ADDRESS             |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
  * **ADDRESS (8:0)**: 9-bit number representing the MIB metric address
  for a specific port.

#### 1.7.2. MIB_CTRL0_REG (0x1005)

This register triggers and monitors the MIB counter polling operation.

##### **Family A:**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|    RESERVED   |GLB| QM|P7 |P6 |P5 |P4 |P3 |P2 |P1 |P0 |RST|BSY|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **GLB (Bit 11)**: `GLOBAL_RESET_MASK (0x800)` - Global MIB counters reset flag.
* **QM (Bit 10)**: `QM_RESET_MASK (0x400)` - Queue Management MIB counters reset flag.
* **P7 (Bit 9)**: `PORT7_RESET_MASK (0x200)` - Port 7 MIB counters reset flag.
* **P6 (Bit 8)**: `PORT6_RESET_MASK (0x100)` - Port 6 MIB counters reset flag.
* **P5 (Bit 7)**: `PORT5_RESET_MASK (0x80)` - Port 5 MIB counters reset flag.
* **P4 (Bit 6)**: `PORT4_RESET_MASK (0x40)` - Port 4 MIB counters reset flag.
* **P3 (Bit 5)**: `PORT3_RESET_MASK (0x20)` - Port 3 MIB counters reset flag.
* **P2 (Bit 4)**: `PORT2_RESET_MASK (0x10)` - Port 2 MIB counters reset flag.
* **P1 (Bit 3)**: `PORT1_RESET_MASK (0x8)` - Port 1 MIB counters reset flag.
* **P0 (Bit 2)**: `PORT0_RESET_MASK (0x4)` - Port 0 MIB counters reset flag.
* **RST (Bit 1)**: `RESET_FLAG_MASK (0x2)` - MIB reset operation execution flag.
* **BSY (Bit 0)**: `BUSY_FLAG_MASK (0x1)` - MIB engine busy status indicator flag.

##### **Families B, and D:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED|VAL|GLB| QM|P7 |P6 |P5 |P4 |P3 |P2 |P1 |P0 |RST|BSY|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **VAL (Bit 12)**: `RESET_VALUE_MASK (0x1000)` - MIB counter reset value configuration flag.
* **GLB (Bit 11)**: `GLOBAL_RESET_MASK (0x800)` - Global MIB counters reset flag.
* **QM (Bit 10)**: `QM_RESET_MASK (0x400)` - Queue Management MIB counters reset flag.
* **P7 (Bit 9)**: `PORT7_RESET_MASK (0x200)` - Port 7 MIB counters reset flag.
* **P6 (Bit 8)**: `PORT6_RESET_MASK (0x100)` - Port 6 MIB counters reset flag.
* **P5 (Bit 7)**: `PORT5_RESET_MASK (0x80)` - Port 5 MIB counters reset flag.
* **P4 (Bit 6)**: `PORT4_RESET_MASK (0x40)` - Port 4 MIB counters reset flag.
* **P3 (Bit 5)**: `PORT3_RESET_MASK (0x20)` - Port 3 MIB counters reset flag.
* **P2 (Bit 4)**: `PORT2_RESET_MASK (0x10)` - Port 2 MIB counters reset flag.
* **P1 (Bit 3)**: `PORT1_RESET_MASK (0x8)` - Port 1 MIB counters reset flag.
* **P0 (Bit 2)**: `PORT0_RESET_MASK (0x4)` - Port 0 MIB counters reset flag.
* **RST (Bit 1)**: `RESET_FLAG_MASK (0x2)` - MIB reset operation execution flag.
* **BSY (Bit 0)**: `MIB_CTRL0_BUSY_FLAG_MASK (0x1)` - MIB engine busy status indicator flag.

##### **Family C:**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|P10| P9| P8|VAL|GLB| QM|P7 |P6 |P5 |P4 |P3 |P2 |P1 |P0 |RST|BSY|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **P10 (Bit 15)**: `PORT10_RESET_MASK (0x8000)` - Port 10 MIB counters reset flag.
* **P9 (Bit 14)**: `PORT9_RESET_MASK (0x4000)` - Port 9 MIB counters reset flag.
* **P8 (Bit 13)**: `PORT8_RESET_MASK (0x2000)` - Port 8 MIB counters reset flag.
* **VAL (Bit 12)**: `RESET_VALUE_MASK (0x1000)` - MIB counter reset value configuration flag.
* **GLB (Bit 11)**: `GLOBAL_RESET_MASK (0x800)` - Global MIB counters reset flag.
* **QM (Bit 10)**: `QM_RESET_MASK (0x400)` - Queue Management MIB counters reset flag.
* **P7 (Bit 9)**: `PORT7_RESET_MASK (0x200)` - Port 7 MIB counters reset flag.
* **P6 (Bit 8)**: `PORT6_RESET_MASK (0x100)` - Port 6 MIB counters reset flag.
* **P5 (Bit 7)**: `PORT5_RESET_MASK (0x80)` - Port 5 MIB counters reset flag.
* **P4 (Bit 6)**: `PORT4_RESET_MASK (0x40)` - Port 4 MIB counters reset flag.
* **P3 (Bit 5)**: `PORT3_RESET_MASK (0x20)` - Port 3 MIB counters reset flag.
* **P2 (Bit 4)**: `PORT2_RESET_MASK (0x10)` - Port 2 MIB counters reset flag.
* **P1 (Bit 3)**: `PORT1_RESET_MASK (0x8)` - Port 1 MIB counters reset flag.
* **P0 (Bit 2)**: `PORT0_RESET_MASK (0x4)` - Port 0 MIB counters reset flag.
* **RST (Bit 1)**: `RESET_FLAG_MASK (0x2)` - MIB reset operation execution flag.
* **BSY (Bit 0)**: `MIB_CTRL0_BUSY_FLAG_MASK (0x1)` - MIB engine busy status indicator flag.

#### 1.7.3. MIB_CTRL1_REG (0x1006)

This register expands MIB_CTRL0_REG port resets for family A. Families B, C and D do not
use register 0x1006 but reuse the MIB_CTRL1_REG name for `0x1008`, while family A calls it
MIB_CTRL2_REG.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED        |P15|P14|P13|P12|P11|P10| P9| P8|RSV|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **P15 (Bit 9)**: `PORT15_RESET_MASK (0x200)` - Port 15 MIB counters reset flag.
* **P14 (Bit 8)**: `PORT14_RESET_MASK (0x100)` - Port 14 MIB counters reset flag.
* **P13 (Bit 7)**: `PORT13_RESET_MASK (0x80)` - Port 13 MIB counters reset flag.
* **P12 (Bit 6)**: `PORT12_RESET_MASK (0x40)` - Port 12 MIB counters reset flag.
* **P11 (Bit 5)**: `PORT11_RESET_MASK (0x20)` - Port 11 MIB counters reset flag.
* **P10 (Bit 4)**: `PORT10_RESET_MASK (0x10)` - Port 10 MIB counters reset flag.
* **P9 (Bit 3)**: `PORT9_RESET_MASK (0x8)` - Port 9 MIB counters reset flag.
* **P8 (Bit 2)**: `PORT8_RESET_MASK (0x4)` - Port 8 MIB counters reset flag.

#### 1.7.4 MIB_COUNTER (0x1000 + w)

The sequence of registers 0x1000..0x1003 holds the metric data selected by
MIB_ADDRESS_REG after MIB_CTRL0_BUSY_FLAG_MASK at MIB_CTRL0_REG clears.

All current MIB metrics uses either 2 or 4 words. When it uses 4 words (64-bit)
the layout is:

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                      METRIC DATA [63:48]                      | 0x1000
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                      METRIC DATA [47:32]                      | 0x1001
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                      METRIC DATA [31:16]                      | 0x1002
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                      METRIC DATA [15:0]                       | 0x1003
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

When a metric uses 2 words (32-bit), it will share the 4 words with another metric,
with one occupying the higher registers and the other one the lower ones.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                     METRIC DATA A [31:16]                     | 0x1000
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                     METRIC DATA A [15:0]                      | 0x1001
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                     METRIC DATA B [31:16]                     | 0x1002
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                     METRIC DATA B [15:0]                      | 0x1003
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

#### 1.7.5. L2 Flush Interface (Dynamic Table Purge)

The selective or total purging of dynamic MAC addresses relies on specific registers tailored to each family:

* **Base Ports Mapping (`L2_FLUSH_PORT_REG` - `0x0A36`):** Present in all families for quick control over ports 0 to 7.
* **Extension Ports (`L2_FLUSH_PORT_EXT_REG` - `0x0A35`):** Exclusively used by **Family C** to cover the additional extension ports (EXT0 to EXT2). This functionality is not natively supported by hardware in Families B and D.
* **Advanced Conditional Purge (VLAN/FID):** **Families B, C, and D** gain the `L2_FLUSH_CTRL1_REG` (`0x0A37`) and `L2_FLUSH_CTRL2_REG` (`0x0A38`) registers, allowing entries to be purged based on refined filters (e.g., clearing only dynamic entries associated with a specific VLAN or Forwarding ID).

| Logical Name | Family A | Family B | Family C | Family D | Function / Usage |
| --- | --- | --- | --- | --- | --- |
| `L2_FLUSH_PORT_REG` | `0x0A36` | `0x0A36` | `0x0A36` | `0x0A36` | **Bits (7:0):** PORT_MSK. **Bits (15:8):** BUSY. (Ports 0 to 7). |
| `L2_FLUSH_PORT_EXT_REG` | `**Not found**` | `**Not found**` | `0x0A35` | `**Not found**` | **Bits (2:0):** PORT_EXT_MSK. **Bits (5:3):** BUSY. (EXT0 to EXT2).|
| `L2_FLUSH_CTRL1_REG` | `**Not found**` | `0x0A37` | `0x0A37` | `0x0A37` | **Bits (11:0):** VID. **Bits (15:12):** FID. Used in modes below.|
| `L2_FLUSH_CTRL2_REG` | `**Not found**` | `0x0A38` | `0x0A38` | `0x0A38` | **Bits (1:0):** MODE (0=Port, 1=Port+VID). **Bit (2:2):** TYPE (0=Dynamic).|
| `L2_FLUSH_CTRL3_REG` | `**Not found**` | `**Not found**` | `0x0A39` | `0x0A39` | **Bits (0:0):** MSK. Additional global Flush trigger.|

#### 1.7.5.1. L2_FLUSH_PORT_REG (0x0A36) / REG_FORCE_FLUSH

This register triggers or checks the status of the dynamic table flush operation for the primary ports (ports 0 to 7).

##### **Family A:**

Family A maps this register layout cleanly to a basic trigger address without separate bitfield macros or split status lines within its native files, handling full system purges via an indivisible instruction.

##### **Families B, C, and D:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          BUSY_STATUS          |       FORCE_FLUSH_PORTMASK    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **BUSY_STATUS (15:8)**: `RTL8367B_BUSY_STATUS_MASK` / `RTL8367C_BUSY_STATUS_MASK` / `RTL8367D_BUSY_STATUS_MASK` (`0xFF00`). Per-port flush engine busy execution status flags.
* **FORCE_FLUSH_PORTMASK (7:0)**: `RTL8367B_FORCE_FLUSH_PORTMASK_MASK` / `RTL8367C_FORCE_FLUSH_PORTMASK_MASK` / `RTL8367D_FORCE_FLUSH_PORTMASK_MASK` (`0xFF`). Port mask selector to execute dynamic or static flushes on physical ports 0 to 7.


#### 1.7.5.2. L2_FLUSH_PORT_EXT_REG (0x0A35) / REG_FORCE_FLUSH1

This register handles extended port flushes for families expanding past 8 logical port channels.
> ⚠️ **Peer Correction Note:** In **Family A**, the register address `0x0A35` is actually used for `RTL8370_REG_PORT_EFID_CTRL3` to map the Enhanced Filtering Database IDs for ports 12 to 15 rather than any flush operation. It is completely **Not Found** as a flush register on Families B and D.

##### **Family C:**
```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                       RESERVED        | BUSY_ST1  |  PMASK1   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **BUSY_ST1 (5:3)**: `RTL8367C_BUSY_STATUS1_MASK` (`0x38`). Busy execution status flags for the extended logical port channels.
* **PMASK1 (2:0)**: `RTL8367C_PORTMASK1_MASK` (`0x7`). Extended port mask selector targeting logical ports 8 to 10.


#### 1.7.5.3. L2_FLUSH_CTRL1_REG (0x0A37) / REG_L2_FLUSH_CTRL1

This register specifies the explicit Filtering ID (FID) or Customer VLAN ID (VID) filters used during advanced dynamic purging operations.

##### **Family A:**

* **Not Found** on Family A hardware.

##### **Families B and C:**
```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|    FLUSH_FID  |                   FLUSH_VID                   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **FLUSH_FID (15:12)**: `RTL8367B_LUT_FLUSH_FID_MASK` / `RTL8367C_LUT_FLUSH_FID_MASK` (`0xF000`). 4-bit Forwarding Database ID filter parameter.
* **FLUSH_VID (11:0)**: `RTL8367B_LUT_FLUSH_VID_MASK` / `RTL8367C_LUT_FLUSH_VID_MASK` (`0xFFF`). 12-bit Customer VLAN ID filter parameter.

##### **Family D:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|FLU_FID|                   FLUSH_VID                   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **FLU_FID (13:12)**: `RTL8367D_LUT_FLUSH_FID_MASK` (`0x3000`). 2-bit compressed Forwarding Database ID filter parameter.
* **FLUSH_VID (11:0)**: `RTL8367D_LUT_FLUSH_VID_MASK` (`0xFFF`). 12-bit Customer VLAN ID filter parameter.

#### 1.7.5.4. L2_FLUSH_CTRL2_REG (0x0A38) / REG_L2_FLUSH_CTRL2

This register configures the primary condition filters (Modes) and entry classification targets (Types) for purging execution.

##### **Family A:**
* **Not Found** on Family A hardware.

##### **Families B, C, and D:**
```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                       RESERVED                    |TYP|MODE   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **TYP (2:2)**: `RTL8367B_LUT_FLUSH_TYPE_MASK` / `RTL8367C_LUT_FLUSH_TYPE_MASK` / `RTL8367D_LUT_FLUSH_TYPE_MASK` (`0x4`). Purge row classification selection. `0` = Dynamic entries only, `1` = Both static and dynamic entries.
* **MODE (1:0)**: `RTL8367B_LUT_FLUSH_MODE_MASK` / `RTL8367C_LUT_FLUSH_MODE_MASK` / `RTL8367D_LUT_FLUSH_MODE_MASK` (`0x3`). Condition lookup rule filter:
* `0` = Port-based flush mode.
* `1` = Port + VID based flush mode.
* `2` = Port + FID/MSTI based flush mode.

#### 1.7.5.5. L2_FLUSH_CTRL3_REG (0x0A39) / REG_L2_FLUSH_CTRL3

This register serves as an automated global trigger to flush the entire Look-Up Table simultaneously.

##### **Families A and B:**
* **Not Found** on Family A and Family B configurations.

##### **Families C and D:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                              RESERVED                     |MSK|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MSK (0:0)**: `RTL8367C_L2_FLUSH_CTRL3_MASK` / `RTL8367D_L2_FLUSH_CTRL3_MASK` (`0x1`). Writing `1` initiates a complete table flush including static and dynamic entries; hardware automatically clears this bit to `0` once the operation finishes.


### 1.8. LED Configuration and Control

This section covers the registers responsible for configuring the switch LEDs, including system-wide LED modes, parallel/serial IO enables, and CPU-forced LED overrides.

| Logical Name | Family A | Family B | Family C | Family D | Function / Usage |
| --- | --- | --- | --- | --- | --- |
| `LED_SYS_CONFIG_REG` | `0x1B00` | `0x1B00` | `0x1B00` | `0x1B00` | LED system configuration (interfaces, EEE LPI, power-on). |
| `LED_SYS_CONFIG2_REG` | `**Not found**` | `0x1B01` | `0x1B01` | `0x1B01` | LED system configuration 2 (bypass, speed mode). |
| `LED_MODE_REG` | `0x1B02` | `0x1B02` | `0x1B02` | `0x1B02` | LED force rate and general behavior modes. |
| `LED_CONFIGURATION_REG`| `0x1B03` | `0x1B03` | `0x1B03` | `0x1B03` | LED group mode configuration (selectors for LED0/1/2). |
| `CPU_FORCE_LED_CFG_REG`| `0x1B07` | `0x1B07` | `0x1B07` | `0x1B07` | CPU forced LED configuration mode. |
| `CPU_FORCE_LED_REG(g, p)`| `0x1B08+(g*2)+(p/8)` | `0x1B08+(g*2)` | `0x1B08+(g*2)+(p/8)` | `0x1B08+(g*2)` | CPU forced LED states per port p and LED group g. |
| `PARA_LED_IO_EN3_REG` | `**Not found**` | `**Not found**` | `0x1B13` | `**Not found**` | Parallel LED IO enable 3 (upper ports). |
| `PARA_LED_IO_EN1_REG` | `0x1B24` | `0x1B24` | `0x1B24` | `0x1B24` | Parallel LED IO enable 1. |
| `PARA_LED_IO_EN2_REG` | `0x1B25` | `0x1B25` | `0x1B25` | `0x1B25` | Parallel LED IO enable 2. |
| `SCAN0_LED_IO_EN1_REG` | `0x1B26` | `0x1B26` | `0x1B26` | `0x1B26` | Scan0 LED IO enable (serial/buzzer config). |
| `SERIAL_LED_CTRL_REG` | `**Not found**` | `**Not found**` | `0x1B3A` | `**Not found**` | Serial LED control sequence and group number. |

> **Note on `0x1B13`:** In the vendor SDK, this register is named `EXT_GPIO_ENABLE_CTRL1` for Family A, serving a different semantic purpose. Therefore, it is marked as **Not found** under the `PARA_LED_IO_EN3_REG` mapping for Family A. The `rtl8365mb` driver maps `0x1B13` as `PARA_LED_IO_EN3_REG` specifically to configure the parallel LED IO for logical ports 8 and above, which are physically present in the 11-port layout of Family C.

> **Note on `0x1B3A`:** Serial LED control appears uniquely mapped in Family C (`RTL8367C_REG_SERIAL_LED_CTRL`) within the provided vendor definitions.

#### 1.8.1. LED_SYS_CONFIG_REG (0x1B00)

This register configures the global system-level LED behaviors, including EEE (Energy Efficient Ethernet) Low Power Idle (LPI) LED modes, power-on defaults, and IO disabling.

##### **Family A**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|  RSV  |LPM|LPE|L10|C10|  LPI  |ACT| P2| P1| P0|IOD|SER|  SEL  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RSV (15:14)**: `DUMMY_0`. Reserved/Dummy bits.
* **LPM (13:13)**: `LED_EEE_LPI_MODE`. EEE LPI LED Mode.
* **LPE (12:12)**: `LED_EEE_LPI_EN`. EEE LPI LED Enable.
* **L10 (11:11)**: `LED_EEE_LPI_10`. EEE LPI 10M configuration.
* **C10 (10:10)**: `LED_EEE_CAP_10`. EEE 10M capability flag.
* **LPI (9:8)**: `LED_LPI_SEL`. 2-bit Low Power Idle LED selector.
* **ACT (7:7)**: `SERI_LED_ACT_LOW`. Serial LED active-low configuration.
* **P2 (6:6)**: `LED_POWERON_2`. Power-on default LED state 2.
* **P1 (5:5)**: `LED_POWERON_1`. Power-on default LED state 1.
* **P0 (4:4)**: `LED_POWERON_0`. Power-on default LED state 0.
* **IOD (3:3)**: `LED_IO_DISABLE`. Disables physical IO for LEDs.
* **SER (2:2)**: `SEL_SERIAL_LED`. Serial LED selection.
* **SEL (1:0)**: `LED_SELECT`. 2-bit LED selection mask.

##### **Family B**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|SOM|LPM|LPE|L10|C10|  LPI  |ACT| P2| P1| P0|IOD|  RSV  |SEL|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RSV (15:15)**: `DUMMY_15`. Reserved/Dummy bit.
* **SOM (14:14)**: `LED_SERIAL_OUT_MODE`. Serial output mode configuration.
* **LPM (13:13)**: `LED_EEE_LPI_MODE`. EEE LPI LED Mode.
* **LPE (12:12)**: `LED_EEE_LPI_EN`. EEE LPI LED Enable.
* **L10 (11:11)**: `LED_EEE_LPI_10`. EEE LPI 10M configuration.
* **C10 (10:10)**: `LED_EEE_CAP_10`. EEE 10M capability flag.
* **LPI (9:8)**: `LED_LPI_SEL`. 2-bit Low Power Idle LED selector.
* **ACT (7:7)**: `SERI_LED_ACT_LOW`. Serial LED active-low configuration.
* **P2 (6:6)**: `LED_POWERON_2`. Power-on default LED state 2.
* **P1 (5:5)**: `LED_POWERON_1`. Power-on default LED state 1.
* **P0 (4:4)**: `LED_POWERON_0`. Power-on default LED state 0.
* **IOD (3:3)**: `LED_IO_DISABLE`. Disables physical IO for LEDs.
* **RSV (2:1)**: `DUMMY_2_1`. Reserved/Dummy bits.
* **SEL (0:0)**: `LED_SELECT`. 1-bit LED selection mask.

##### **Family C**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|SOM|LPM|LPE|L10|C10|  LPI  |ACT| P2| P1| P0|IOD|RSV|  SEL  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RSV (15:15)**: `DUMMY_15`. Reserved/Dummy bit.
* **SOM (14:14)**: `LED_SERIAL_OUT_MODE`. Serial output mode configuration.
* **LPM (13:13)**: `LED_EEE_LPI_MODE`. EEE LPI LED Mode.
* **LPE (12:12)**: `LED_EEE_LPI_EN`. EEE LPI LED Enable.
* **L10 (11:11)**: `LED_EEE_LPI_10`. EEE LPI 10M configuration.
* **C10 (10:10)**: `LED_EEE_CAP_10`. EEE 10M capability flag.
* **LPI (9:8)**: `LED_LPI_SEL`. 2-bit Low Power Idle LED selector.
* **ACT (7:7)**: `SERI_LED_ACT_LOW`. Serial LED active-low configuration.
* **P2 (6:6)**: `LED_POWERON_2`. Power-on default LED state 2.
* **P1 (5:5)**: `LED_POWERON_1`. Power-on default LED state 1.
* **P0 (4:4)**: `LED_POWERON_0`. Power-on default LED state 0.
* **IOD (3:3)**: `LED_IO_DISABLE`. Disables physical IO for LEDs.
* **RSV (2:2)**: `DUMMY_2_2`. Reserved/Dummy bit.
* **SEL (1:0)**: `LED_SELECT`. 2-bit LED selection mask.

##### **Family D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|SOM|LPM|LPE|L10|C10|  LPI  |ACT| P2| P1| P0|IOD|RSV|SE2|SEL|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RSV (15:15)**: `DUMMY_15`. Reserved/Dummy bit.
* **SOM (14:14)**: `LED_SERIAL_OUT_MODE`. Serial output mode configuration.
* **LPM (13:13)**: `LED_EEE_LPI_MODE`. EEE LPI LED Mode.
* **LPE (12:12)**: `LED_EEE_LPI_EN`. EEE LPI LED Enable.
* **L10 (11:11)**: `LED_EEE_LPI_10`. EEE LPI 10M configuration.
* **C10 (10:10)**: `LED_EEE_CAP_10`. EEE 10M capability flag.
* **LPI (9:8)**: `LED_LPI_SEL`. 2-bit Low Power Idle LED selector.
* **ACT (7:7)**: `SERI_LED_ACT_LOW`. Serial LED active-low configuration.
* **P2 (6:6)**: `LED_POWERON_2`. Power-on default LED state 2.
* **P1 (5:5)**: `LED_POWERON_1`. Power-on default LED state 1.
* **P0 (4:4)**: `LED_POWERON_0`. Power-on default LED state 0.
* **IOD (3:3)**: `LED_IO_DISABLE`. Disables physical IO for LEDs.
* **RSV (2:2)**: `DUMMY_2`. Reserved/Dummy bit.
* **SE2 (1:1)**: `LED_SERIAL2`. Secondary serial LED configuration.
* **SEL (0:0)**: `LED_SELECT`. 1-bit LED selection mask.


#### 1.8.2. LED_SYS_CONFIG2_REG (0x1B01)

This register provides additional system-level LED configuration, specifically controlling the LED speed mode and bypass settings for the GATE LPTD logic.

##### **Family A**

* **Not found** on Family A hardware.

##### **Families B, C, and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                        RESERVED                       |GBP|SPD|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RESERVED (15:2)**: `DUMMY`. Reserved/Dummy bits.
* **GBP (1:1)**: `GATE_LPTD_BYPASS`. Gate LPTD bypass configuration flag.
* **SPD (0:0)**: `LED_SPD_MODE`. LED speed mode configuration.

#### 1.8.3. LED_MODE_REG (0x1B02)

This register configures various LED behavior modes, including buzzer rates, loop detection settings, and force rates.

##### **Family A**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RTT|BZD|  BZR  |LDM|  SPT  |EDL|  LDR  |  FRC  |    SLR    |SUP|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RTT (15:15)**: `RTCT_TEST_TIME`. Real-Time Cable Test time configuration.
* **BZD (14:14)**: `LED_BUZZ_DUTY`. LED buzzer duty cycle configuration.
* **BZR (13:12)**: `BUZZER_RATE`. 2-bit buzzer rate selection.
* **LDM (11:11)**: `LOOP_DETECT_MODE`. Loop detection mode indicator.
* **SPT (10:9)**: `SEL_PWRON_TIME`. 2-bit power-on time selection.
* **EDL (8:8)**: `EN_DLINK_LED`. Enable D-Link LED mode.
* **LDR (7:6)**: `LOOP_DETECT_RATE`. 2-bit loop detection rate.
* **FRC (5:4)**: `FORCE_RATE`. 2-bit forced rate configuration.
* **SLR (3:1)**: `SEL_LEDRATE`. 3-bit LED rate selection.
* **SUP (0:0)**: `SPEED_UP`. Speed up mode indicator.

##### **Families B, C, and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|DLT|BZD|  BZR  |LDM|  SPT  |EDL|  LDR  |  FRC  |    SLR    |SUP|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **DLT (15:15)**: `DLINK_TIME`. D-Link time configuration.
* **BZD (14:14)**: `LED_BUZZ_DUTY`. LED buzzer duty cycle configuration.
* **BZR (13:12)**: `BUZZER_RATE`. 2-bit buzzer rate selection.
* **LDM (11:11)**: `LOOP_DETECT_MODE`. Loop detection mode indicator.
* **SPT (10:9)**: `SEL_PWRON_TIME`. 2-bit power-on time selection.
* **EDL (8:8)**: `EN_DLINK_LED`. Enable D-Link LED mode.
* **LDR (7:6)**: `LOOP_DETECT_RATE`. 2-bit loop detection rate.
* **FRC (5:4)**: `FORCE_RATE`. 2-bit forced rate configuration.
* **SLR (3:1)**: `SEL_LEDRATE`. 3-bit LED rate selection.
* **SUP (0:0)**: `SPEED_UP`. Speed up mode indicator.

#### 1.8.4. LED_CONFIGURATION_REG (0x1B03)

This register configures the specific behavior or grouping modes for individual LED sets (LED0, LED1, and LED2), as well as data LED flashing patterns.

##### **Families A, B, C, and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|SEL|  DAT  |     LED2      |     LED1      |     LED0      |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RSV (15:15)**: `LED_CONFIGURATION_DUMMY` / `DUMMY_0`. Reserved/Dummy bit.
* **SEL (14:14)**: `LED_CONFIG_SEL`. LED configuration selector.
* **DAT (13:12)**: `DATA_LED`. 2-bit data LED mode configuration.
* **LED2 (11:8)**: `LED2_CFG`. 4-bit configuration mode for LED2 group.
* **LED1 (7:4)**: `LED1_CFG`. 4-bit configuration mode for LED1 group.
* **LED0 (3:0)**: `LED0_CFG`. 4-bit configuration mode for LED0 group.

#### 1.8.5. CPU_FORCE_LED_CFG_REG (0x1B07)

This register configures the global forcing mode for CPU-controlled LEDs.

##### **Families A, B, C, and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |    LED_FORCE_MODE     |  FRC  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RESERVED (15:8)**: `DUMMY`. Reserved/Dummy bits.
* **LED_FORCE_MODE (7:2)**: `LED_FORCE_MODE`. 6-bit LED force mode configuration pattern.
* **FRC (1:0)**: `FORCE_MODE`. 2-bit CPU force mode selector.

| `CPU_FORCE_LED_REG(g, p)`| `0x1B08 + (g*2) + (p/8)` | `0x1B08 + (g*2)` | `0x1B08 + (g*2) + (p/8)` | `0x1B08 + (g*2)` | CPU forced LED states per port `p` and LED group `g`. |

#### 1.8.6. CPU_FORCE_LED_REG(g, p) (0x1B08 + (g * 2) + (p / 8))

Each 16-bit register packs the CPU-forced LED mode for 8 ports (2 bits each). The register address encodes the LED group index `g` (0 to 2) and the port group (e.g., ports 0 to 7, or 8 to 15).

##### **Families A, B, C, and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| PORT_7| PORT_6| PORT_5| PORT_4| PORT_3| PORT_2| PORT_1| PORT_0|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **PORT_x (2 bits)**: Forced LED mode for port `x` (where `x = p % 8`) in LED group `g`. Field offset = `(p % 8) * 2`.
  * `0` = Normal / Auto
  * `1` = Force Blink
  * `2` = Force Off
  * `3` = Force On

> **Note:** Families B and D have up to 8 ports, meaning `p/8` is always `0` and all ports fit within a single 16-bit register per LED group. Families A and C use the subsequent register (`+ 1`) for ports 8 and above.


#### 1.8.7. PARA_LED_IO_EN3_REG (0x1B13)

This register enables the parallel LED IO signals for the upper logical ports (ports 8 and above) which are present in the extended 11-port layout of Family C.

##### **Families A, B, and D**

* **Not found** (Family A uses `0x1B13` as `EXT_GPIO_ENABLE_CTRL1` with completely different semantics; Families B and D lack upper ports and do not implement this register).

##### **Family C**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|         RESERVED          |    G2_UP  |    G1_UP  |    G0_UP  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RESERVED (15:9)**: Reserved bits.
* **G2_UP (8:6)**: `LED2_PARA_P10_08`. Parallel LED IO enable for LED group 2, upper ports 10 to 8 (bit 8 = port 10; bit 6 = port 8).
* **G1_UP (5:3)**: `LED1_PARA_P10_08`. Parallel LED IO enable for LED group 1, upper ports 10 to 8 (bit 5 = port 10; bit 3 = port 8).
* **G0_UP (2:0)**: `LED0_PARA_P10_08`. Parallel LED IO enable for LED group 0, upper ports 10 to 8 (bit 2 = port 10; bit 0 = port 8).

#### 1.8.8. PARA_LED_IO_EN1_REG (0x1B24)

This register enables the parallel LED IO signals for LED groups 0 and 1 on the base physical ports.

##### **Families A and C**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             L1_EN             |             L0_EN             |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **L1_EN (15:8)**: `LED1_PARA_P07_00`. Parallel LED IO enable for LED group 1, ports 7 to 0 (1-bit per port).
* **L0_EN (7:0)**: `LED0_PARA_P07_00`. Parallel LED IO enable for LED group 0, ports 7 to 0 (1-bit per port).

##### **Families B and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|    RSV    |       L1_EN       |    RSV    |       L0_EN       |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RSV (15:13)**: `DUMMY`. Reserved/Dummy bits.
* **L1_EN (12:8)**: `LED1_PARA_P04_00`. Parallel LED IO enable for LED group 1, ports 4 to 0 (1-bit per port).
* **RSV (7:5)**: `DUMMY`. Reserved/Dummy bits.
* **L0_EN (4:0)**: `LED0_PARA_P04_00`. Parallel LED IO enable for LED group 0, ports 4 to 0 (1-bit per port).

#### 1.8.9. PARA_LED_IO_EN2_REG (0x1B25)

This register enables the parallel LED IO signals for LED group 2 on the base physical ports.

##### **Families A and C**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |             L2_EN             |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RESERVED (15:8)**: `DUMMY`. Reserved/Dummy bits.
* **L2_EN (7:0)**: `LED2_PARA_P07_00`. Parallel LED IO enable for LED group 2, ports 7 to 0 (1-bit per port).

##### **Families B and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                  RESERVED                 |       L2_EN       |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RESERVED (15:5)**: `DUMMY`. Reserved/Dummy bits.
* **L2_EN (4:0)**: `LED2_PARA_P04_00`. Parallel LED IO enable for LED group 2, ports 4 to 0 (1-bit per port).

#### 1.8.10. SCAN0_LED_IO_EN1_REG (0x1B26)

This register configures the Scan0 LED IO enables, including the serial data/clock pins and the loop detection buzzer enable.

##### **Family A**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             BIP               |    BIS    |  RSV  |BUZ|DAT|CLK|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **BIP (15:8)**: `LED_SCAN0_BI_PORT_EN`. Bi-color port enable for Scan0.
* **BIS (7:5)**: `LED_SCAN0_BI_STA_EN`. Bi-color status enable for Scan0.
* **RSV (4:3)**: `DUMMY_0`. Reserved/Dummy bits.
* **BUZ (2:2)**: `LED_LOOP_DET_BUZZER_EN`. Loop detection buzzer enable.
* **DAT (1:1)**: `LED_SERI_DATA_EN`. Serial LED data pin enable.
* **CLK (0:0)**: `LED_SERI_CLK_EN`. Serial LED clock pin enable.



##### **Families B, C, and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                       RESERVED                    |BUZ|DAT|CLK|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RESERVED (15:3)**: `DUMMY`. Reserved/Dummy bits.
* **BUZ (2:2)**: `LED_LOOP_DET_BUZZER_EN`. Loop detection buzzer enable.
* **DAT (1:1)**: `LED_SERI_DATA_EN`. Serial LED data pin enable.
* **CLK (0:0)**: `LED_SERI_CLK_EN`. Serial LED clock pin enable.



#### 1.8.11. SERIAL_LED_CTRL_REG (0x1B3A)

This register configures the serial LED shift sequence, group number, and port enables. It is exclusively mapped in Family C hardware.

##### **Families A, B, and D**

* **Not found** on Family A, B, and D hardware.

##### **Family C**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|  SEQ  |SQE|  GRP  |                  PEN                  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **RSV (15:15)**: Reserved bit.
* **SEQ (14:13)**: `SERIAL_LED_SHIFT_SEQUENCE`. Serial LED shift sequence configuration.
* **SQE (12:12)**: `SERIAL_LED_SHIFT_SEQUENCE_EN`. Serial LED shift sequence enable.
* **GRP (11:10)**: `SERIAL_LED_GROUP_NUM`. Number of serial LED groups.
* **PEN (9:0)**: `SERIAL_LED_PORT_EN`. 10-bit serial LED port enable mask.

## 2. PHYs REG access mechanism

The Realtek switches provide an indirect access mechanism to read and write PHY
registers, including OCP registers.

The vendor code mentions two PHY register bases
* **Internal PHYs**: `BASE = 0x2000`, `OFFSET = 5`.
* **External PHYs**: `BASE = 0xA000`, `OFFSET = 9`.

However the code just uses the Internal PHYs base.

### 2.1 Direct PHY Access (MDIO controlled switches)

For switches connected to the host via the MDC/MDIO interface, the internal PHYs are directly exposed on the MDIO bus and respond to their respective PHY addresses (typically corresponding to their port numbers). Thus, the host can access the PHY registers directly using standard MDIO read/write operations.

|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`PHY_REG(p, r)`|`0x2000 + (p<<5) + r`|`0x2000 + (p<<5) + r`|`**Not found**`|`**Not found**`|PHY p register r|
|`PHY_OCP_REG(p, r)`|`**Not found**`|`**Not found**`|`0x2000 + (r & 0x3C0)>>6<<8  + (p<<5) + (r & 0x3E)>>1`|`0x2000 + (r & 0x3C0)>>6<<8  + (p<<5) + (r & 0x3E)>>1`|PHY p OCP register r on page `r & 0xFC00` set by GPHY_OCP_MSB_0 |
|`GPHY_OCP_MSB_0`|`**Not found**`|`**Not found**`|`0x1d15`|`0x1d15`|PHY OCP register page for CPU and DW8051 access of PHY_OCP_REG(p, r)|

#### PHY_REG(p, r) (0x2000 + (p<<5) + r)

This register directly access IEEE PHY registers. The register address is formed as:

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|    0x1    |     RESERVED      |  PHY_NUM  |    PHY_OCP_REG    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

p represents the internal PHY number and r is the PHY register (0..0x1F). The register, for MDIO-controlled switches, can be read or written directly as any other register.

##### ** Family A ** #####

For family A, PHY number can be from 0 to 7 (3-bit) and PHY registers are from 0 to 0x1F (5-bit). Only standard IEEE registers are supported.

##### ** Family B ** #####

For family B, PHY number can be from 0 to 4 (3-bit) and PHY OCP registers are from 0 to 0x1F (5-bit). Only standard IEEE registers are supported.

##### ** Families C and D ** #####

These families reused the same register to access OCP registers instead of the standard IEEE. See PHY_OCP_REG.

#### PHY_OCP_REG(p, r) (0x2000 + ((r >> 6) & 0x000F)<<8) + (p<<5) + ((r >> 1) & 0x001F))

While sharing the same 0x2000 address as PHY_REG for families A and B, family C and D only exposes PHY registers as OCP registers.

OCP register addresses are 16-bit and point to a single 8-bit value. The access is divided in two steps:
1. The page is selected using the 6 MSB of the OCP register address.
2. The remainging OCP register address with the PHY address is used to calculate the index in the selected page where the register can be accessed.

As Realtek uses 16-bit values and OCP register addresses points to a single 8-bit value, the least significant bit is ignored as the two following OCP register addresses are always accessed together.

##### ** Families A and B ** #####

These families do not support OCP registers, only standard IEEE direcly mapped at 0x2000-0x2FFF.

##### ** Families C and D ** #####

The OCP register address (OCP_ADD) is decomposed this way into registers:

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| GPHY_OCP_MSB_0_11_6   |PHY_OCP_REG11_8|  PHY_OCP_REG_4_0  |PAR|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* ** GPHY_OCP_MSB_0_11_6(15:10) ** - The 6-most significant bits set the page using GPHY_OCP_MSB_0.
  ** PHY_OCP_REG11_8(9:6) ** - The next 4-most siginificant bits are used to index the register.
  ** PHY_OCP_REG_4_0(5:1) ** - The reaming 5-least siginificant bits are used to index the register.
  ** PAR(0:0) - As OCS address points to a single bit and Realtek registers has 16-bit, the last bit is ignored on read/write operations. That way, OCS register address must always be even.

After the PHY register address [15:10] bits defines the page (in GPHY_OCP_MSB_0[11:6]), the remaining bits and the phy number can be used to index the data register.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|    0x1    |RSV| OCP_ADD[9:6]  |  PHY_NUM  |    OCP_ADD[5:1]   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

And the PHY OCP register at OCP_ADD and OCP_ADD+1 can be accessed at the switch register PHY_OCP_REG(p, r), from range 0x2000-0x2FFF.

#### GPHY_OCP_MSB_0 (0x1d15)

This register define the OCP register page for families C and D. It sets the 15:10 bits (0xfc00) of a 16-bit OCP address (actually 15-bit for these switches). It should be used together with PHY_OCP_REG that uses the 9:1 bits to index the switch register (0x2000-0x2FFF).

##### ** Families A and B ** #####

These families do not support OCP registers, only standard IEEE direcly mapped at 0x2000-0x2FFF.

##### ** Families C and D ** #####

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|    RESERVED   |    CPU_OCPADDR_MSB    |  DW8051_OCPADR_MSB    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **CPU_OCPADDR_MSB (11:6)**: `CPU_OCPADR_MSB (0x0FC0)` - CPU OCP Address 6 MSB
* **DW8051_OCPADR_MSB (5:0)**: `DW8051_OCPADR_MSB (0x003F)` - DW8051 OCP Address 6 MSB

### 2.2 Indirect PHY Access (via Switch Registers)

The CPU can address the PHY registers through an indirect paging mechanism implemented in the switch's register space. For SMI-controlled switches, the indirect access is the only way to read/write PHY (OCP) registers.

|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`INDIRECT_ACCESS_CTRL`|`0x1F00`|`0x1F00`|`0x1F00`|`0x1F00`|Command (Bit 0) and Access direction (Bit 1).|
|`INDIRECT_ACCESS_STATUS`|`0x1F01`|`0x1F01`|`0x1F01`|`0x1F01`|Internal transaction status (Busy flags).|
|`INDIRECT_ACCESS_ADDRESS`|`0x1F02`|`0x1F02`|`0x1F02`|`0x1F02`|Formatted PHY address (Base + Port + Offset).|
|`INDIRECT_ACCESS_WRITE_DATA`|`0x1F03`|`0x1F03`|`0x1F03`|`0x1F03`|Data to write to the PHY.|
|`INDIRECT_ACCESS_READ_DATA`|`0x1F04`|`0x1F04`|`0x1F04`|`0x1F04`|Data read from the PHY.|

** Note: ** the driver rtl8365mb uses the indirect access independently from the interface used to controle the switch (SMI or MDIO).

The sequence of reading/writes is:
* Check if all busy flags at INDIRECT_ACCESS_STATUS are cleared.
* Sets the address:
  * Families A and B:
    * Write PHY_REG(p, r) to INDIRECT_ACCESS_ADDRESS.
  * Families C and D:
    * Set the page at GPHY_OCP_MSB_0.
    * Write PHY_OCP_REG(p, r) to INDIRECT_ACCESS_ADDRESS.
* Write data to INDIRECT_ACCESS_WRITE_DATA (if writting).
* Issue the indirect access by writting to INDIRECT_ACCESS_CTRL.
* Read data to INDIRECT_ACCESS_READ_DATA (if reading).
* Wait for completition checking if all busy flags at INDIRECT_ACCESS_STATUS are cleared.

#### 2.2.1. INDIRECT_ACCESS_CTRL (0x1F00)

This register initiates the indirect access transaction to the PHYs.

**Families A, B, C, and D:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                    |RW | C |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```

* **RW (1:1)**: Operation direction.
  * `0` = Read PHY register
  * `1` = Write PHY register.
* **C (0:0)**: Command trigger. Write `1` to execute transaction; hardware clears it to `0` upon completion.

#### 2.2.2. INDIRECT_ACCESS_STATUS (0x1F01)

This register returns the status of the indirect access mechanism, indicating if the bus is busy.

**Family A:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                |PHY|SDS|MDX|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```

* **PHY (2:2)**: `PHY_BUSY_MASK` (`0x4`). PHY is busy.
* **SDS (1:1)**: `SDS_BUSY_MASK` (`0x2`). SerDes is busy.
* **MDX (0:0)**: `MDX_BUSY_MASK` (`0x1`). MDIO/MDC is busy.

**Families B, C and D:**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                |BSY|RSERVED|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```
* **BSY (2:2)**: `BUSY_MASK` (`0x4`). Mechanism is busy.

**Note**: Family C sets BUSY_MASK as 0x7 but it still defines the offset as 2. It is probaly a bug in vendor API.

#### 2.2.3. INDIRECT_ACCESS_ADDRESS (0x1F02)

This register specifies the target PHY and the register to be accessed.

**Families A and B:**

The register value must be in the 0x2000-0x201F range, and use the same register address from PHY_REG(p, r) used in direct access.


**Families C and D:**

The register value must be in the 0x2000-0x2FFF range, and use the same register address from PHY_OCP_REG(p, r) used in direct access.

The register GPHY_OCP_MSB_0 must also be set the same way as in the direct access.

## 3. Table Access Mechanism

All families share a unified indirect mechanism for manipulating internal hardware tables, including Layer 2 forwarding (L2/FDB), VLAN 4K (CVLAN), Access Control Lists (ACL - rules and actions), and IGMP groups (read-only).

There is a crucial physical divergence in the data staging area: **Family A** uses a contiguous block of mixed registers (`0x0503` to `0x0525`) for both reading and writing operations. Meanwhile, **Families B, C, and D** separate these buses, dedicating the `0x0510–0x0519` block strictly for write operations and the `0x0520–0x0529` block for read operations.

| Logical Name | Family A | Family B | Family C | Family D | Function / Usage |
| --- | --- | --- | --- | --- | --- |
| `TABLE_CTRL` | `0x0500` | `0x0500` | `0x0500` | `0x0500` | Defines the Command, Operation (R/W), and Target Table. |
| `TABLE_ACCESS_ADDR` | `0x0501` | `0x0501` | `0x0501` | `0x0501` | Direct index or address of the table entry to be accessed. |
| `TABLE_LUT_ADDR` | `0x0502` | `0x0502` | `0x0502` | `0x0502` | Hardware execution status (Busy, Hit, and Matched Address). |
| `TABLE_DATA(w)` | `0x0503 + w` | `**Not found**` | `**Not found**` | `**Not found**` | Staging area of 32 words for Read/Write operations. |
| `TABLE_WRITE(w)` | `**Not found**` | `0x0510 + w` | `0x0510 + w` | `0x0510 + w` | Staging area of 16 words for Write operations. |
| `TABLE_READ(w)` | `**Not found**` | `0x0520 + w` | `0x0520 + w` | `0x0520 + w` | Staging area of 16 words for Read operations. |

> **Note:** The Family C API redefines the `0x0502` register internally as `TABLE_ACCESS_STATUS_REG`, while Family D keeps the native `REG_TABLE_LUT_ADDR` nomenclature. Both point to the exact same physical hardware address.

### 3.2. Detailed Registers and Bitfields

### 3.2.1. TABLE_CTRL (0x0500)

#### **Family A**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED    |ST |       RESERVED        |MET|OP |   TABLE   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```
* **ST (12:12)**: `ACCESS_STATUS` (`0x1000`). Target access status bit.
* **MET (5:5)**: `ACCESS_METHOD` (`0x20`). 1-bit access method selector.
  * `0` = Retrieve the entry by MAC address informed in TABLE_DATA.
  * `1` = Retrieve the entry by table index informed in TABLE_ACCESS_ADDR.
* **OP (4:4)**: `COMMAND_TYPE` (`0x10`). Operation direction.
  * `0` = Read.
  * `1` = Write.
* **TABLE (2:0)**: `TABLE_TYPE` (`0x7`). Target table selector.
  * `0` = Reserved.
  * `1` = ACL rule.
  * `2` = ACL action.
  * `3` = CVLAN (Vlan4K).
  * `4` = L2.
  * `5` = Reserved.
  * `6` = Reserved.
  * `7` = Reserved.

#### **Families B, and D**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|     RESERVED      |    SPA    |RSV|  METHOD   |OP |   TABLE   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **SPA (10:8)**: `SPA` (`0x700`). Source Port Address / Target Port index for port-based lookups (3-bit field).
* **METHOD (6:4)**: `ACCESS_METHOD` (`0x70`). Access method selector (3-bit field).
  * `0` = Retrieve the entry by MAC address informed in TABLE_DATA.
  * `1` = Retrieve the entry by table index informed in TABLE_ACCESS_ADDR.
  * `2` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR.
  * `3` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2 Unicast entries.
  * `4` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2 Multicast entries.
  * `5` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L3 Multicast entries.
  * `6` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2/L3 Multicast entries.
  * `7` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2 Unicast entries associated with the port informed in the SPA field.
* **OP (3:3)**: `COMMAND_TYPE` (`0x8`). Operation direction.
  * `0` = Read.
  * `1` = Write.
* **TABLE (2:0)**: `TABLE_TYPE` (`0x7`). Target table selector (L2, CVLAN, ACL, etc.).
  * `0` = Reserved.
  * `1` = ACL rule.
  * `2` = ACL action.
  * `3` = CVLAN (Vlan4K).
  * `4` = L2.
  * `5` = IGMP group (read-only).
  * `6` = Reserved.
  * `7` = Reserved.

#### **Family C**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   RESERVED    |      SPA      |RSV|  METHOD   |OP |   TABLE   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **SPA (11:8)**: `SPA` (`0xF00`). Source Port Address / Target Port index for port-based lookups (4-bit field).
* **METHOD (6:4)**: `ACCESS_METHOD` (`0x70`). Access method selector (3-bit field).
  * `0` = Retrieve the entry by MAC address informed in TABLE_DATA.
  * `1` = Retrieve the entry by table index informed in TABLE_ACCESS_ADDR.
  * `2` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR.
  * `3` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2 Unicast entries.
  * `4` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2 Multicast entries.
  * `5` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L3 Multicast entries.
  * `6` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2/L3 Multicast entries.
  * `7` = Retrieve the next address starting from table index informed in TABLE_ACCESS_ADDR, but only considering L2 Unicast entries associated with the port informed in the SPA field.
* **OP (3:3)**: `COMMAND_TYPE` (`0x8`). Operation direction.
  * `0` = Read.
  * `1` = Write.
* **TABLE (2:0)**: `TABLE_TYPE` (`0x7`). Target table selector (L2, CVLAN, ACL, etc.).
  * `0` = Reserved.
  * `1` = ACL rule.
  * `2` = ACL action.
  * `3` = CVLAN (Vlan4K).
  * `4` = L2.
  * `5` = IGMP group (read-only).
  * `6` = Reserved.
  * `7` = Reserved.

#### 3.2.2. TABLE_ACCESS_ADDR (0x0501)

Inform the address / table index to retrieve/modify or look up from.

#### **Family A**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|                        ADDRESS                        |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
> **Note:** Bit 13 is probably the Address TYPE (see REG_TABLE_LUT_ADDR).

#### **Families B, and D**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|    RESERVED   |                    ADDRESS                    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
> **Note:** Bit 11 is probably the Address TYPE (see REG_TABLE_LUT_ADDR).

#### **Family C**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|  RESERVED |                      ADDRESS                      |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
> **Note:** Bit 12 is probably the Address TYPE (see REG_TABLE_LUT_ADDR).

### 3.2.2. REG_TABLE_LUT_ADDR / TABLE_STATUS_REG (0x0502)

This register monitors the runtime execution status, busy flags, match indications, and target address indexing results of the table access engine.

#### **Family A**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|HIT|TYP|                    ADDRESS                        |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **HIT (14:14)**: `HIT_STATUS` (`0x4000`) - Hit status indicator.
  * `0` = Not found.
  * `1` = Match found.
* **TYP (13:13)**: `TYPE` (`0x2000`) - Address type qualifier.
  * `0` = L2 table.
  * `1` = CAM table.
* **ADDRESS (12:0)**: `ADDRESS` (`0x1FFF`) - 13-bit complete table entry address field.

> **Note:** Busy flag is in TABLE_CTRL for Family A.

#### **Families B and D**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|BSY|HIT|TYP|                   ADDRESS                 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **BSY (13:13)**: `BUSY_FLAG` (`0x2000`) - Table access engine busy status indicator
  * `0` = Ready.
  * `1` = Busy/Executing.
* **HIT (12:12)**: `STATUS` (`0x1000`) - Hit status indicator
  * `0` = Not found.
  * `1` = Match found.
* **TYP (11:11)**: `TYPE` (`0x800`) - Address type qualifier.
  * `0` = L2 table.
  * `1` = CAM table.
* **ADDRESS (10:0)**: `ADDRESS` (`0x7FF`) - 11-bit table entry address field.

#### **Family C**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|AHI|BSY|HIT|TYP|                   ADDRESS                 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **AHI (14:14)**: `ADDRESS_HIGH` (`0x4000`) - Most significant address bit.
* **BSY (13:13)**: `BUSY_FLAG` (`0x2000`) - Table access engine busy status indicator
  * `0` = Ready.
  * `1` = Busy/Executing.
* **HIT (12:12)**: `STATUS` (`0x1000`) - Hit status indicator
  * `0` = Not found.
  * `1` = Match found.
* **TYP (11:11)**: `TYPE` (`0x800`) - Address type qualifier.
  * `0` = L2 table.
  * `1` = CAM table.
* **ADDRESS_LO (10:0)**: `ADDRESS` (`0x7FF`) - 11-bit least significant table entry address field. Must be combined with ADDRESS_HIGH.

### 3.2.3. TABLE_DATA(w) (0x0503 + w)

This block represents the data staging register array unique to Family A. It is used both as input (writting/look up) or reading entries from tabables.
It is composed of 32 sequential registers.

Families B, C and D uses TABLE_WRITE(w) and TABLE_READ(w).

### 3.2.4. TABLE_WRITE(w) (0x0510 + w)

This block represents the data staging register array for Families B, C and D. It is used exclusively as input (writting/look up).
It is composed of 16 sequential registers.

### 3.2.5. TABLE_READ(w) (0x0520 + w)

This block represents the data staging register array for Families B, C and D. It is used exclusively as output (reading).
It is composed of 16 sequential registers.

### 3.3. Operation Flow (Sequence of Access)

Read and write operations must follow the sequences below:

#### Write Flow
1. Ensure the method is idle
* **Family A**: Check ACCESS_STATUS in `TABLE_CTRL`
* **Families B, C, D**: Check `BSY` bit in `TABLE_LUT_ADDR/TABLE_STATUS`.
2. Write the target table entry index to `TABLE_ACCESS_ADDR`.
3. Load the new entry data into the staging area:
* **Family A**: Use the `TABLE_DATA(w)` registers.
* **Families B, C, D**: Use the `TABLE_WRITE(w)` registers.
4. Issue the command by configuring the `TABLE`, `OP=1` fields in `TABLE_CTRL`.
5. Wait until the method is idle again (as in step 1.)

#### Read / Search Flow

1. Ensure the method is idle
* **Family A**: Check ACCESS_STATUS in `TABLE_CTRL`
* **Families B, C, D**: Check `BSY` bit in `TABLE_LUT_ADDR/TABLE_STATUS`.
2A. If performing an associative search (e.g., L2 MAC search), load the search key into:
* **Family A**: `TABLE_DATA(w)` registers
* **Families B, C, D**: `TABLE_WRITE(w)` registers.
2B. If not, write the target table entry index to `TABLE_ACCESS_ADDR`.
3. Issue the command by configuring `TABLE`, `OP=0`, and the appropriate `METHOD` in `TABLE_CTRL_REG`.
5. Wait until the method is idle again (as in step 1.)
5. For associative searches, the corresponding hardware index will be available in the `ADDRESS_STATUS` field of `TABLE_LUT_ADDR/TABLE_STATUS`.
6. Retrieve the table entry structure from the reading region:
* **Family A**: Read from TABLE_DATA(w) registers.
* **Families B, C, D**: Read from `TABLE_READ`.


## 4. Table Structures

Each table and family has its own memory layout and size

### 4.1. ACL Rule

Pending (Not used by rtl8365mb).

### 4.2. ACL Action 

Pending (Not used by rtl8365mb).

### 4.3. CVLAN (Vlan4K)

The 4K VLAN table entry configurations establish a direct 1-to-1 hardware mapping across all 4096 available VIDs.

#### **Family A**

Family A requires a 64-bit row map distributed over 4 sequential words (4 registers) to host its expanded 16-port filtering architecture.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                              MBR                              | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|   MSTI    |                      FID                          | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| UNT1 |            METERIDX            |POL|   VBPRI   |EN |LUR| Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RSV  |                            UNT2                        | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MBR**: (Word 0, bits 15:0) `mbr` — Complete 16-bit physical port member mask for the VLAN.
* **MSTI**: (Word 1, bits 15:12) `msti` — 4-bit Multiple Spanning Tree Instance index.
* **FID**: (Word 1, bits 11:0) `fid` — 12-bit VLAN Forwarding ID mapping.
* **UNT1**: (Word 2, bits 15:14) `untag1` — Lower 2 bits (bits 1:0) of the untagged egress portmask.
* **METERIDX**: (Word 2, bits 13:6) `meteridx` — 8-bit Traffic Limiter Meter entry index.
* **POL**: (Word 2, bit 5) `envlanpol` — 1-bit VLAN Egress Priority Remarking configuration enable flag.
* **VBPRI**: (Word 2, bits 4:2) `vbpri` — 3-bit VLAN Port Priority value.
* **EN**: (Word 2, bit 1) `vbpen` — 1-bit Port-based VLAN Priority override control flag.
* **LUR**: (Word 2, bit 0) `lurep` — 1-bit L2 Lookup learning bypass configuration flag.
* **UNT2**: (Word 3, bits 13:0) `untag2` — Upper 14 bits (bits 15:2) of the untagged egress portmask.

#### **Family B**

Family B compacts its registers into a tight 32-bit layout across 2 sequential words (2 registers), optimizing for its native 8-port design constraint.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             UNTAG             |              MBR              | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|IS |        METERIDX       |POL|   VBPRI   |EN | FID_MST   | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **MBR**: (Word 0, bits 7:0) `mbr` — 8-bit member portmask for ports 0–7.
* **UNTAG**: (Word 0, bits 15:8) `untag` — 8-bit untagged portmask for ports 0–7.
* **FID_MST**: (Word 1, bits 3:0) `fid_msti` — 4-bit multiplexed Forwarding ID / Multiple Spanning Tree Instance field.
* **EN**: (Word 1, bit 4) `vbpen` — 1-bit Port-based VLAN Priority override control flag.
* **VBPRI**: (Word 1, bits 7:5) `vbpri` — 3-bit VLAN Port Priority value.
* **POL**: (Word 1, bit 8) `envlanpol` — 1-bit VLAN Egress Priority Remarking enable flag.
* **METERIDX**: (Word 1, bits 13:9) `meteridx` — 5-bit Traffic Limiter Meter index.
* **IS**: (Word 1, bit 14) `ivl_svl` — 1-bit Independent/Shared Learning selector flag (`0` = SVL, `1` = IVL).

#### **Family C**

Family C uses a 48-bit layout mapping parameters onto 3 words (3 registers) to natively coordinate an 11-port logical map alongside extended meter indexing depths.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           UNTAG_LO            |            MBR_LO             | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|IS |       METER_LO        |POL|   VBPRI   |EN |  FID_MST  | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|               RESERVED                |MH |  UNT_HI   |MBR_HI | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **MBR_LO**: (Word 0, bits 7:0) `mbr` — Lower member portmask bits for ports 0–7.
* **UNTAG_LO**: (Word 0, bits 15:8) `untag` — Lower untagged portmask bits for ports 0–7.
* **FID_MST**: (Word 1, bits 3:0) `fid_msti` — 4-bit Shared Forwarding ID / Multiple Spanning Tree Instance configuration index field.
* **EN**: (Word 1, bit 4) `vbpen` — 1-bit Port-based VLAN Priority override enable flag.
* **VBPRI**: (Word 1, bits 7:5) `vbpri` — 3-bit VLAN Port Priority value.
* **POL**: (Word 1, bit 8) `envlanpol` — 1-bit VLAN Egress Priority Remarking configuration enable flag.
* **METER_LO**: (Word 1, bits 13:9) `meteridx` — Lower 5 bits of the traffic Meter index (`meteridx[4:0]`).
* **IS**: (Word 1, bit 14) `ivl_svl` — 1-bit Independent/Shared Learning configuration flag (`0` = SVL, `1` = IVL).
* **RSV**: (Word 1, bit 15) — Reserved padding bit.
* **MBR_HI**: (Word 2, bits 2:0) `mbr` — Extension Member Portmask bits for logical ports 8–10 (`mbr[10:8]`).
* **UNT_HI**: (Word 2, bits 5:3) `untag` — Extension Untagged Portmask bits for logical ports 8–10 (`untag[10:8]`).
* **MH**: (Word 2, bit 6) `meteridx` — Most significant bit (MSB) of the traffic Meter index (`meteridx[5]`).

> **Note:** Word 0 and Word 1 are equal to Family B

#### **Family D**

Family D eliminates policy overrides, priority structures, and meter references from the CVLAN lookup tree, processing table configurations via an 8-port optimized 3-word map where only the first 2 words are actively driven.

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             UNTAG             |              MBR              | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                     RESERVED                  |IS |CHK|FID_MST| Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MBR**: (Word 0, bits 7:0) `mbr` — 8-bit member portmask targeting physical ports 0–7.
* **UNTAG**: (Word 0, bits 15:8) `untag` — 8-bit untagged egress portmask targeting physical ports 0–7.
* **FID_MST**: (Word 1, bits 1:0) `fid_msti` — 2-bit compressed Forwarding ID / Multiple Spanning Tree Instance index field.
* **CHK**: (Word 1, bit 2) `svlan_chk_ivl_svl` — 1-bit SVLAN Independent/Shared check control flag.
* **IS**: (Word 1, bit 3) `ivl_svl` — 1-bit Independent/Shared Learning configuration flag (`0` = SVL, `1` = IVL).

### 4.4. L2 (FDB Lookup)

The Layer 2 Forwarding Database (FDB / LUT) represents the core dynamic and static MAC address table space. Across generations, this architecture transformed from a legacy 7-word contiguous structure to structured 5-word or 6-word blocks to coordinate decreasing physical port lines and unified Layer 3 multicast optimization flags.

#### **Family A**

Family A uses a 7-word wide table layout. Due to its 16-port pipeline architecture, it maps full linear port masks directly into its auto-learning entry space.

##### **Unicast L2**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSV|   AGE     |      SPA      |SAE|DAE|   MACPRI  |ATH|BLK|STA| Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC5              |            RESERVED           | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC3              |              MAC4             | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC2              |              MAC1             | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             FID1              |              MAC0             | Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |IPM|   EFID    |     FID2      | Word 5
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                        |VAL| Word 6
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **STA**: (Word 0, bit 0) `smi_auto.static_bit` — Static entry flag. Disables aging processing for the row.
* **BLK**: (Word 0, bit 1) `smi_auto.block` — Blocked address flag. Drops matching source or destination traffic.
* **ATH**: (Word 0, bit 2) `smi_auto.auth` — 802.1X authorization status for the entry.
* **MACPRI**: (Word 0, bits 5:3) `smi_auto.macpri` — 3-bit priority value assigned to the matching MAC entry.
* **DAE**: (Word 0, bit 6) `smi_auto.da_en` — Destination MAC priority classification enable flag.
* **SAE**: (Word 0, bit 7) `smi_auto.sa_en` — Source MAC priority classification enable flag.
* **SPA**: (Word 0, bits 11:8) `smi_auto.spa` — 4-bit Source Port Address mapping (ports 0 to 15).
* **AGE**: (Word 0, bits 14:12) `smi_auto.age` - 3-bit entry aging timer state.
* **MAC5**: (Word 1, bits 15:8) `smi_auto.mac5` - MAC address octet 5.
* **MAC4**: (Word 2, bits 7:0) `smi_auto.mac4` - MAC address octet 4.
* **MAC3**: (Word 2, bits 15:8) `smi_auto.mac3` - MAC address octet 3.
* **MAC2**: (Word 3, bits 7:0) `smi_auto.mac2` - MAC address octet 2.
* **MAC1**: (Word 3, bits 15:8) `smi_auto.mac1` - MAC address octet 1.
* **MAC0**: (Word 4, bits 7:0) `smi_auto.mac0` - MAC address octet 0. 
* **FID1**: (Word 4, bits 15:8) `smi_auto.fid1` - lower 8 bits of Forwarding ID.
* **FID2**: (Word 5, bits 3:0) `smi_auto.fid2` — Upper 4 bits of the Forwarding ID.
* **EFID**: (Word 5, bits 6:4) `smi_auto.efid` — 3-bit Enhanced Filtering Database ID.
* **IPM**: (Word 5, bit 7) `smi_auto.ipmul` — Layer 3 IP Multicast lookup validation selector
  * `0` = L2 MAC lookup.
  * `1` = L3 Multicast.
* **VAL**: (Word 6, bit 0) `smi_auto.valid` — Hardware entry valid indicator.

##### **Multicast L2**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           PORTMASK1           |SAE|DAE|   MACPRI  |ATH|BLK|STA| Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC5              |           PORTMASK2           | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC3              |              MAC4             | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC1              |              MAC2             | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             FID1              |              MAC0             | Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|           RESERVED            |IPM|   EFID    |      FID2     | Word 5
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                           RESERVED                        |VAL| Word 6
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```

* **STA**: (Word 0, bit 0) `smi_l2mul.static_bit` — Static entry flag (forced to `1`).
* **BLK**: (Word 0, bit 1) `smi_l2mul.block` — Blocked multicast entry status flag.
* **ATH**: (Word 0, bit 2) `smi_l2mul.auth` — Multicast row 802.1X authorization flag.
* **MACPRI**: (Word 0, bits 5:3) `smi_l2mul.macpri` — 3-bit priority configuration assigned to this multicast stream.
* **DAE**: (Word 0, bit 6) `smi_l2mul.da_en` — Destination-based multicast priority enable flag.
* **SAE**: (Word 0, bit 7) `smi_l2mul.sa_en` — Source-based multicast priority enable flag.
* **PORTMASK1**: (Word 0, bits 15:8) `smi_l2mul.portmask1` — Lower 8 bits (ports 0 to 7) of the multicast forwarding portmask.
* **PORTMASK2**: (Word 1, bits 7:0) `smi_l2mul.portmask2` — Upper 8 bits (ports 8 to 15) of the multicast forwarding portmask.
* **MAC5**: (Word 1, bits 15:8) `smi_l2mul.mac5` — Multicast MAC address octet 5.
* **MAC4**: (Word 2, bits 7:0) `smi_l2mul.mac4` — Multicast MAC address octet 4.
* **MAC3**: (Word 2, bits 15:8) `smi_l2mul.mac3` — Multicast MAC address octet 3.
* **MAC2**: (Word 3, bits 7:0) `smi_l2mul.mac2` — Multicast MAC address octet 2.
* **MAC1**: (Word 3, bits 15:8) `smi_l2mul.mac1` — Multicast MAC address octet 1.
* **MAC0**: (Word 4, bits 7:0) `smi_l2mul.mac0` — Multicast MAC address octet 0.
* **FID1**: (Word 4, bits 15:8) `smi_l2mul.fid1` — Lower 8 bits of the Forwarding ID.
* **FID2**: (Word 5, bits 3:0) `smi_l2mul.fid2` — Upper 4 bits of the Forwarding ID.
* **EFID**: (Word 5, bits 6:4) `smi_l2mul.efid` — 3-bit Enhanced Filtering Database ID.
* **IPM**: (Word 5, bit 7) `smi_l2mul.ipmul` — Layer 3 IP Multicast identifier (forced to `0`).
* **VAL**: (Word 6, bit 0) `smi_l2mul.valid` — Hardware row validation indicator.

#### **Family B**

Family B maps entries onto a 6-word structure. Ports are constrained to an 8-port model.

##### **Unicast L2**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC4                 |             MAC5              | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC2                 |             MAC3              | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC0                 |             MAC1              | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|IS |L3M|                    CVID_FID                   | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |BLK|ATH|    AGE    |    SPA    |SAE|      FID      | Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                  RESERVED             |STA|FWD|    LPRI   |DBE| Word 5
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MAC5**: (Word 0, bits 7:0) `smi_auto.mac5` - MAC address octet 5.
* **MAC4**: (Word 0, bits 15:8) `smi_auto.mac4` - MAC address octet 4.
* **MAC3**: (Word 1, bits 7:0) `smi_auto.mac3` - MAC address octet 3.
* **MAC2**: (Word 1, bits 15:8) `smi_auto.mac2` - MAC address octet 2.
* **MAC1**: (Word 2, bits 7:0) `smi_auto.mac1` - MAC address octet 1.
* **MAC0**: (Word 2, bits 15:8) `smi_auto.mac0` - MAC address octet 0.
* **CVID_FID**: (Word 3, bits 11:0) `smi_auto.cvid_fid` — 12-bit combined CVLAN ID or Forwarding ID string.
* **L3M**: (Word 3, bit 12) `smi_auto.l3lookup` — Layer 3 lookup initialization validation bit.
* **IS**: (Word 3, bit 13) `smi_auto.ivl_svl` — Independent/Shared learning classification mode bit.
* **FID**: (Word 4, bits 3:0) `smi_auto.fid` — 4-bit localized Forwarding ID mapping index.
* **SAE**: (Word 4, bit 4) `smi_auto.sa_en` — Source MAC priority enforcement bit.
* **SPA**: (Word 4, bits 7:5) `smi_auto.spa` — 3-bit physical Source Port Address line (ports 0 to 7).
* **AGE**: (Word 4, bits 10:8) `smi_auto.age` — 3-bit entry lifetime aging counter.
* **ATH**: (Word 4, bit 11) `smi_auto.auth` — Port authorization state identifier.
* **BLK**: (Word 4, bit 12) `smi_auto.sa_block` — Ingress source hardware block enforcement flag. Bits (`efid`) map filtering domains.
* **DBE**: (Word 5, bit 0) `smi_auto.da_block` — Egress destination block enforcement flag.
* **LPRI**: (Word 5, bits 3:1) `smi_auto.lut_pri` — 3-bit Lookup Table absolute priority override profile.
* **FWD**: (Word 5, bit 4) `smi_auto.fwd_en` — Priority forwarding selection enable bit.
* **STA**: (Word 5, bit 5) `smi_auto.nosalearn` — Static entry flag. Clears aging tracking.

##### **Multicast L2**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC4              |              MAC5             | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC2              |              MAC3             | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC0              |              MAC1             | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|RSERVED|IS |L3M|                    CVID_FID                   | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|            IGMPIDX            |              MBR              | Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             RESERVED              |VAL|STA|FWD|   LPRI    |IGM| Word 5
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MAC5**: (Word 0, bits 7:0) `smi_l2mul.mac5` — Multicast MAC address octet 5.
* **MAC4**: (Word 0, bits 15:8) `smi_l2mul.mac4` — Multicast MAC address octet 4.
* **MAC3**: (Word 1, bits 7:0) `smi_l2mul.mac3` — Multicast MAC address octet 3.
* **MAC2**: (Word 1, bits 15:8) `smi_l2mul.mac2` — Multicast MAC address octet 2.
* **MAC1**: (Word 2, bits 7:0) `smi_l2mul.mac1` — Multicast MAC address octet 1.
* **MAC0**: (Word 2, bits 15:8) `smi_l2mul.mac0` — Multicast MAC address octet 0.
* **CVID_FID**: (Word 3, bits 11:0) `smi_l2mul.cvid_fid` — 12-bit VLAN ID or Filtering ID configuration.
* **L3M**: (Word 3, bit 12) `smi_l2mul.l3lookup` — L3 lookup validation bit (forced to `0`).
* **IS**: (Word 3, bit 13) `smi_l2mul.ivl_svl` — IVL/SVL classification filter selector.
* **MBR**: (Word 4, bits 7:0) `smi_l2mul.mbr` — 8-bit forwarding port mask for ports 0–7.
* **IGMPIDX**: (Word 4, bits 15:8) `smi_l2mul.igmpidx` — 8-bit internal hardware IGMP table index mapping.
* **IGM**: (Word 5, bit 0) `smi_l2mul.igmp_asic` — IGMP hardware tracking enable bit.
* **LPRI**: (Word 5, bits 3:1) `smi_l2mul.lut_pri` — 3-bit static stream destination priority override.
* **FWD**: (Word 5, bit 4) `smi_l2mul.fwd_en` — Multicast stream priority classification enable.
* **STA**: (Word 5, bit 5) `smi_l2mul.nosalearn` — Static persistent row configuration marker.
* **VAL**: (Word 5, bit 6) `smi_l2mul.valid` — Entry row valid status bit.

#### **Family C**

Family C expands the logical tracking framework over 6 registers to support an 11-port layout.

##### **Unicast L2**
```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC4                 |             MAC5              | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC2                 |             MAC3              | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC0                 |             MAC1              | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|SAH|RSV|IS |L3M|                    CVID_FID                   | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |BLK|ATH|    AGE    |  SPA_LO   |SAE|      FID      | Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                  RESERVED             |STA|FWD|    LPRI   |DBE| Word 5
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```
* **MAC5**: (Word 0, bits 7:0) `smi_auto.mac5` - MAC address octet 5.
* **MAC4**: (Word 0, bits 15:8) `smi_auto.mac4` - MAC address octet 4.
* **MAC3**: (Word 1, bits 7:0) `smi_auto.mac3` - MAC address octet 3.
* **MAC2**: (Word 1, bits 15:8) `smi_auto.mac2` - MAC address octet 2.
* **MAC1**: (Word 2, bits 7:0) `smi_auto.mac1` - MAC address octet 1.
* **MAC0**: (Word 2, bits 15:8) `smi_auto.mac0` - MAC address octet 0.
* **CVID_FID**: (Word 3, bits 11:0) `cvid_fid` — 12-bit core VLAN ID or Forwarding ID string.
* **L3M**: (Word 3, bit 12) `l3lookup` — Layer 3 IP multicast lookup flag.
* **IS**: (Word 3, bit 13) `ivl_svl` — Independent/Shared learning selection bit.
* **SAH**: (Word 3, bit 15) `spa` — Most significant bit of Source Port Address.
* **FID**: (Word 4, bits 3:0) `fid` — 4-bit localized Forwarding ID index.
* **SAE**: (Word 4, bit 4) `sa_en` — Source MAC priority selection enforcement bit.
* **SPA_LO**: (Word 4, bits 7:5) `spa` — Lower 3 bits of Source Port Address. Used together with SAH.
* **AGE**: (Word 4, bits 10:8) `age` — 3-bit entry lifetime aging tracker.
* **ATH**: (Word 4, bit 11) `auth` — 802.1X authentication state identifier.
* **BLK**: (Word 4, bit 12) `sa_block` — Ingress source hardware block line. Bits (`efid`) map the filtering database.
* **DBE**: (Word 5, bit 0) `da_block` — Egress destination block override bit.
* **LPRI**: (Word 5, bits 3:1) `lut_pri` — 3-bit absolute priority value profile.
* **FWD**: (Word 5, bit 4) `fwd_en` — Priority forwarding selection enable bit.
* **STA**: (Word 5, bit 5) `nosalearn` — Static entry flag. Stops the aging cycle.

##### **Multicast L2**

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC4              |              MAC5             | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC2              |              MAC3             | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC0              |              MAC1             | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|MBR_HI |IS |L3M|                    CVID_FID                   | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|            IGMPIDX            |            MBR_LO             | Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|            RESERVED           |MBE|RSV|STA|FWD|   LPRI    |IGM| Word 5
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MAC5**: (Word 0, bits 7:0) `mac.octet[5]` — Multicast MAC address octet 5.
* **MAC4**: (Word 0, bits 15:8) `mac.octet[4]` — Multicast MAC address octet 4.
* **MAC3**: (Word 1, bits 7:0) `mac.octet[3]` — Multicast MAC address octet 3.
* **MAC2**: (Word 1, bits 15:8) `mac.octet[2]` — Multicast MAC address octet 2.
* **MAC1**: (Word 2, bits 7:0) `mac.octet[1]` — Multicast MAC address octet 1.
* **MAC0**: (Word 2, bits 15:8) `mac.octet[0]` — Multicast MAC address octet 0.
* **CVID_FID**: (Word 3, bits 11:0) `cvid_fid` — 12-bit CVID or FID grouping tag.
* **L3M**: (Word 3, bit 12) `l3lookup` — L3 lookup validation bit (forced to `0`).
* **IS**: (Word 3, bit 13) `ivl_svl` — 1-bit Independent/Shared learning selection bit.
* **MBR_HI**: (Word 3, bits 15:14) `mbr` — Intermediate 2 bits (`mbr[9:8]`) of the 11-port multicast forwarding mask.
* **MBR_LO**: (Word 4, bits 7:0) `mbr` — Lower 8 bits (`mbr[7:0]`) of the 11-port multicast forwarding mask.
* **IGMPIDX**: (Word 4, bits 15:8) `igmpidx` — 8-bit dynamic hardware IGMP tracking index assignment.
* **IGM**: (Word 5, bit 0) `igmp_asic` — Automated ASIC IGMP snooping validation flag.
* **LPRI**: (Word 5, bits 3:1) `lut_pri` — 3-bit absolute priority tag assignment.
* **FWD**: (Word 5, bit 4) `fwd_en` — Priority classification forwarding path enforcer.
* **STA**: (Word 5, bit 5) `nosalearn` — Static persistent entry indicator flag.
* **MBE**: (Word 5, bit 7) `mbr` — Most significant bit (`mbr[10]`) of the 11-port multicast forwarding mask.

#### **Family D**

Family D optimizes data packing into 5 sequential words.

##### **Unicast L2**
```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC4                 |             MAC5              | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC2                 |             MAC3              | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|          MAC0                 |             MAC1              | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|SPA_LO |IS |L3M|                    CVID_FID                   | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                   RESERVED        |STA|RSERVED|    AGE    |SHI| Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MAC5**: (Word 0, bits 7:0) `smi_auto.mac5` - MAC address octet 5.
* **MAC4**: (Word 0, bits 15:8) `smi_auto.mac4` - MAC address octet 4.
* **MAC3**: (Word 1, bits 7:0) `smi_auto.mac3` - MAC address octet 3.
* **MAC2**: (Word 1, bits 15:8) `smi_auto.mac2` - MAC address octet 2.
* **MAC1**: (Word 2, bits 7:0) `smi_auto.mac1` - MAC address octet 1.
* **MAC0**: (Word 2, bits 15:8) `smi_auto.mac0` - MAC address octet 0.
* **CVID_FID**: (Word 3, bits 11:0) `cvid_fid` — 12-bit integrated CVLAN ID or Forwarding ID string.
* **L3M**: (Word 3, bit 12) `l3lookup` — Layer 3 IP multicast lookup flag.
* **IS**: (Word 3, bit 13) `ivl_svl` — 1-bit Independent/Shared learning selection bit.
* **SPA_LO**: (Word 3, bits 15:14) `spa` — Lower 2 bits of Source Port Address.
* **SHI**: (Word 4, bit 0) `spa` — Most significant bit of Source Port Address.
* **AGE**: (Word 4, bits 3:1) `age` — 3-bit entry lifetime aging tracker.
* **STA**: (Word 4, bit 6) `nosalearn` — Static entry flag. Bypasses hardware aging cycles. Bits [15:7] are zero-padded hardware constants.

##### **Multicast L2**

```text
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC4              |              MAC5             | Word 0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC2              |              MAC3             | Word 1
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|             MAC0              |              MAC1             | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|MBR_LO |IS |L3M|                    CVID_FID                   | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                   RESERVED        |STA|        MBR_HI         | Word 4
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* **MAC5**: (Word 0, bits 7:0) `mac.octet[5]` — Multicast MAC address octet 5.
* **MAC4**: (Word 0, bits 15:8) `mac.octet[4]` — Multicast MAC address octet 4.
* **MAC3**: (Word 1, bits 7:0) `mac.octet[3]` — Multicast MAC address octet 3.
* **MAC2**: (Word 1, bits 15:8) `mac.octet[2]` — Multicast MAC address octet 2.
* **MAC1**: (Word 2, bits 7:0) `mac.octet[1]` — Multicast MAC address octet 1.
* **MAC0**: (Word 2, bits 15:8) `mac.octet[0]` — Multicast MAC address octet 0.
* **CVID_FID**: (Word 3, bits 11:0) `cvid_fid` — 12-bit targeted CVLAN ID or Forwarding ID alignment string.
* **L3M**: (Word 3, bit 12) `l3lookup` — Layer 3 lookup bit (forced to `0`).
* **IS**: (Word 3, bit 13) `ivl_svl` — 1-bit Independent/Shared learning selection bit.
* **MBR_LO**: (Word 3, bits 15:14) `mbr` — Lower 2 bits (`mbr[1:0]`) of the physical multicast forwarding mask.
* **MBR_HI**: (Word 4, bits 5:0) `mbr` — Upper 6 bits (`mbr[7:2]`) of the physical multicast forwarding mask.
* **STA**: (Word 4, bit 6) `nosalearn` — Static persistent row assignment selector flag.

### 4.5. IGMP group

Pending (Not used by rtl8365mb).


