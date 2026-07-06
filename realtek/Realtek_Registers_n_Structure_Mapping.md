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
  system traffic is sent. Must be used with THI.
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

Each register encodes the VLAN MC index for two ports (8 bits per port).
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
- **Families B and D**: 0x0A32..0x0A33.
- **Family C**: 0x0A32..0x0A34.

**Note:** Family D reused 0x0A32 as `LUT_CFG2`, which was present in Family C at `0x0a3a`.

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
||           METERID            |POL|   VBPRI   |EN |REP| Word 2
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
* **REP (Word 2, bit 0)**: Lookup Replace?? Replicate?? Replay?? Representation??.
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
|   RESERVED    |             METERIDX      |POL|   VBPRI   |EN | Word 2
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| RESERVED  |                      EVID                         | Word 3
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

```
* **MEMBER (Word 0, bits 10:0)**: `MBR_MASK (0x7FF)` - port member mask for the VLAN.
* **FID_MSTI (Word 1, bits 3:0)**: `CTRL1_MASK (0xF)` - Shared Forwarding ID / Multiple Spanning Tree Instance configuration bits.
* **METERIDX (Word 2, bits 11:5)**: `METERIDX_MASK (0x7E0)` - Traffic Meter Index.
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
|`PHY_OCP_REG(p, r)`|`**Not found**`|`**Not found**`|`0x2000 + (p<<5) + r`|`0x2000 + (p<<5) + r`|PHY p OCP register r|
|`GPHY_OCP_MSB_0`|`**Not found**`|`**Not found**`|`0x1d15`|`0x1d15`|TODO|

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

#### PHY_OCP_REG(p, r) (0x2000 + ((r >> 6) & 0x000F)<<8)  + (p<<5) + ((r >> 1) & 0x001F))

While sharing the same 0x2000 address as PHY_REG for families A and B, family C and D only exposes PHY registers as OCP registers.

OCP register addresses are 16-bit and point to a single 8-bit value. The access is divided in two steps:
1. The page is selected using the 6 MSB of the OCP register address.
2. The remainging OCP register address with the PHY address is used to calculate the index in the selected page where the register can be accessed.

As Realtek uses 16-bit values and OCP register addresses points to a single 8-bit value, the least significant bit is ignored as the two following OCP register addresses are always accessed together.

##### ** Families A and B ** #####

These families do not support OCP registers, only standard IEEE direcly mapped at 0x2000-0x2FFF.

##### ** Families C and D ** #####

The OCP register address (OCP_ADD) is decomposed this way:

```
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| GPHY_OCP_MSB_0[11:6]  |PHY_OCP_REG[]  | PHY_OCP_REG[4:0]  |PAR|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
```
* ** GPHY_OCP_MSB_0[11:6](15:10) ** - The 6-most significant bits set the page using GPHY_OCP_MSB_0.
  ** PHY_OCP_REG[:](9:6) ** - The next 4-most siginificant bits are used to index the register, together with PHY_OCP_REG_5_1.
  ** PHY_OCP_REG[4:0](5:1) ** - The next 5-most siginificant bits are used to index the register, together with PHY_OCP_REG_9_6.
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
* **CPU_OCPADDR_MSB (11:6)**: `PORT10_RESET_MASK (0x0FC0)` - CPU OCP Address MSB
* **DW8051_OCPADR_MSB (5:0)**: `DW8051_OCPADR_MSB (0x003F)` - DW8051 OCP Address MSB

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

## 3. Table Access and Indirect Mechanisms

All families perfectly share the same Unified Table
mechanism (`0x0500`) and the OCP Indirect mechanism for PHYs (`0x1F00`). This
implies extremely high code reusability across families.

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

##### **Families A, B, C, and D:**

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

##### **Families A, B, C, and D:**

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


|Logical Name|Family A |Family B |Family C |Family D |Function / Usage|
|-|-|-|-|-|-|
|`L2_FLUSH_PORT_REG`|`0x0A36`|`0x0A36`|`0x0A36`|`0x0A36`|**Bits (7:0):** PORT_MSK. **Bits (15:8):** BUSY. (Ports 0 to 7).|
|`L2_FLUSH_PORT_EXT_REG`|`0x0A35`|`**Not found**`|`0x0A35`|`**Not found**`|**Bits (2:0):** PORT_EXT_MSK. **Bits (5:3):** BUSY. (EXT0 to EXT2).|
|`L2_FLUSH_CTRL1_REG`|`**Not found**`|`0x0A37`|`0x0A37`|`0x0A37`|**Bits (11:0):** VID. **Bits (15:12):** FID. Used in modes below.|
|`L2_FLUSH_CTRL2_REG`|`**Not found**`|`0x0A38`|`0x0A38`|`0x0A38`|**Bits (1:0):** MODE (0=Port, 1=Port+VID). **Bit (2:2):** TYPE (0=Dynamic).|
|`L2_FLUSH_CTRL3_REG`|`**Not found**`|`**Not found**`|`0x0A39`|`0x0A39`|**Bits (0:0):** MSK. Additional global Flush trigger.|

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

