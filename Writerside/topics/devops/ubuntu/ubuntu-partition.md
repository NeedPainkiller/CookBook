# 디스크 & 파티션 관리

## 저장소 검토{id="ubuntu_partition_1"}

### 용량 확인 {id="ubuntu_partition_1_1"}

```bash
sudo df -h
```

#### 예시

```bash
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              6.3G  1.7M  6.3G   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   98G   13G   80G  14% /
tmpfs                               32G     0   32G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/nvme0n1p2                     2.0G  253M  1.6G  14% /boot
/dev/nvme0n1p1                     1.1G  6.1M  1.1G   1% /boot/efi
tmpfs                              6.3G  4.0K  6.3G   1% /run/user/1000
```

### 디스크 및 파티션 확인 {id="ubuntu_partition_1_2"}

```bash
sudo fdisk -l
```

#### 예시

```bash
Disk /dev/nvme0n1: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
Disk model: CT1000P3SSD8
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 7868E63D-D3AC-4727-B8EE-7186B5EF7F64

Device           Start        End    Sectors   Size Type
/dev/nvme0n1p1    2048    2203647    2201600     1G EFI System
/dev/nvme0n1p2 2203648    6397951    4194304     2G Linux filesystem
/dev/nvme0n1p3 6397952 1953521663 1947123712 928.5G Linux filesystem


Disk /dev/sda: 3.64 TiB, 4000787030016 bytes, 7814037168 sectors
Disk model: WDC WD40EZAX-00C
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/ubuntu--vg-ubuntu--lv: 100 GiB, 107374182400 bytes, 209715200 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

- 물리 다스크 구성과 파티션 구성은 다음과 같다
    - `/dev/nvme0n1` : nvme SSD (931.51 GiB)
        - 파티션 구성은 다음과 같다
            - `/dev/nvme0n1p1` : EFI System
            - `/dev/nvme0n1p2` : Linux filesystem
            - `/dev/nvme0n1p3` : Linux filesystem
    - `/dev/sda` : HDD (3.64 TiB)

- 논리 볼륨은 다음과 같다
    - `/dev/mapper/ubuntu--vg-ubuntu--lv` : LVM (100 GiB)

- Issue 1) 논리 볼륨 (`/dev/mapper/ubuntu--vg-ubuntu--lv`) 은 100 GiB 로 생성되었으나 실제 어느 파티션에 묶인 볼륨인지 확인할 수 없다
- Issue 2) `/dev/nvme0n1` 은 파티션이 최초 설치시 자동 으로 생성 되었으나 `/dev/sda` 는 파티션이 생성되지 않았다

## 시스템 논리 볼륨 확장 {id="ubuntu_partition_2"}

### 논리 볼륨 (`/dev/mapper/ubuntu--vg-ubuntu--lv`) 살펴보기 {id="ubuntu_partition_2_1"}

- `ubuntu--vg-ubuntu--lv` 볼륨은 논리 볼륨으로 fdisk 명령어로는 실제 어느 물리 디스크에 묶여 있는지 확인할 수 없다
- `vg-ubuntu--lv` 이름을 가진 볼륨은 LVM(Linux Volume Manager) 에서 관리하는 볼륨 그룹(`ubuntu-vg`)에 묶여 있으며 이는 Ubuntu 시스템을 위한 볼륨 그룹이다
- 볼륨 그룹(`ubuntu-vg`)은 물리 디스크와 논리 볼륨을 묶어서 관리한다
- 볼륨 그룹은 `/dev/nvme0n1` 또는 `/dev/sda` 디스크의 하나 또는 여러 파티션에 걸쳐 있을 수 있다
- 이를 확인하기 위해서는 LVM(Linux Volume Manager) 명령어를 사용해야 한다

<tabs>
    <tab title="논리 볼륨 정보">
        <code-block lang="bash">
          sudo lvdisplay
        </code-block>
        <sub>조회 결과</sub>
        <code-block lang="bash">
            --- Logical volume ---
            LV Path                /dev/ubuntu-vg/ubuntu-lv # 논리 볼륨의 경로
            LV Name                ubuntu-lv # 논리 볼륨의 이름
            VG Name                `ubuntu-vg` # 이 논리 볼륨이 속한 볼륨 그룹의 이름
            LV UUID                zECVzc-JTMI-lBp1-q9rX-HMfU-0tEp-fKfF7R # 논리 볼륨의 고유 식별자(UUID)
            LV Write Access        read/write # 논리 볼륨은 읽기 및 쓰기 접근이 가능
            LV Creation host, time ubuntu-server, 2023-11-24 01:08:59 +0900 # 이 논리 볼륨은 ubuntu-server 호스트에서 2023년 11월 24일에 생성
            LV Status              available # 논리 볼륨의 상태는 사용 가능(available)
            # open                 1 # 현재 열려 있는(사용 중인) 논리 볼륨의 수는 1개
            LV Size                100.00 GiB # 논리 볼륨의 크기는 100 GiB
            Current LE             25600 # 현재 할당된 논리적 확장(LE)의 수는 25600
            Segments               1 # 이 논리 볼륨은 1개의 세그먼트로 구성
            Allocation             inherit # 할당 방식은 상속(inherit). 이는 볼륨 그룹의 할당 정책을 따른다는 의미
            # 섹터를 미리 읽는 설정은 자동(auto)으로 되어 있으며, 현재 256 섹터로 설정
            Read ahead sectors     auto
            - currently set to     256
            Block device           253:0 #  이 논리 볼륨은 블록 장치 253:0로 표시
        </code-block>
<list>
<li>
<p>`ubuntu-vg` 볼륨 그룹에서  /dev/ubuntu-vg/ubuntu-lv 을 관리하는 것을 확인하였다</p>
</li>
</list>
    </tab>
    <tab title="볼륨 그룹 정보">
        <code-block lang="bash">
        sudo vgdisplay 
        </code-block>
        <sub>조회 결과</sub>
        <code-block lang="bash">
            --- Volume group ---
            VG Name               `ubuntu-vg` # 볼륨 그룹 이름
            System ID
            Format                lvm2  # 볼륨 그룹의 포맷은 LVM2, LVM의 두 번째 버전
            Metadata Areas        1 # 메타데이터 영역의 수 (볼륨 그룹의 메타데이터가 저장되는 곳)
            Metadata Sequence No  2 # 메타데이터 버전
            VG Access             read/write # 볼륨 그룹은 읽기/쓰기 접근이 가능
            VG Status             resizable # 볼륨 그룹은 확장 가능(resizable) 상태
            #  최대 논리 볼륨 (LV) 수는 설정되지 않았고, 현재 생성된 논리 볼륨 수는 1개, 현재 열려 있는(사용 중인) 논리 볼륨 수도 1개
            MAX LV                0
            Cur LV                1
            Open LV               1
            # 최대 물리적 볼륨 (PV) 수는 설정되지 않았으며, 현재 물리적 볼륨 수와 활성화된 물리적 볼륨 수는 각각 1개
            Max PV                0
            Cur PV                1
            Act PV                1
            VG Size               &lt; 928.46 GiB # 볼륨 그룹의 전체 크기
            PE Size               4.00 MiB # 물리적 확장(PE)의 크기
            Total PE              237685 # 전체 물리적 확장의 수
            Alloc PE / Size       25600 / 100.00 GiB # 할당된 물리적 확장의 수는 25600개이며, 이는 총 100 GiB
            Free  PE / Size       212085 / &lt; 828.46 GiB # 사용 가능한 물리적 확장의 수는 212085개이며, 이는 총 828.46 GiB
            VG UUID               3nV7xi-zq5K-1WvA-rxkC-ZYdx-dl9a-0RvxRd # 볼륨 그룹의 고유 식별자(UUID)
        </code-block>
        <list>
            <li>
                <p>`ubuntu-vg` 볼륨 그룹이 928.46 GiB 크기를 가지고 있으며, 100 GiB 논리 볼륨이 할당되어 있고, 828.46 GiB의 여유 공간이 있음을 알수 있고</p>
            </li>
            <li>
                <p>해당 볼륨을 확장할 수 있으며, 추가적인 논리 볼륨을 할당할 수 있다</p>
            </li>
        </list>
    </tab>
    <tab title="볼륨 그룹 - 물리 파티션 매핑 정보">
        <code-block lang="bash">
          sudo pvs
        </code-block>
        <sub>조회 결과</sub>
        <code-block lang="bash">
            PV             VG        Fmt  Attr PSize    PFree
            /dev/nvme0n1p3 ubuntu-vg lvm2 a--  &lt; 928.46g &lt; 828.46g
        </code-block>
        <table>
            <thead>
                    <tr>
                        <th>항목</th>
                        <th>설명</th>
                        <th>비고</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>PV</td>
                        <td>물리적 볼륨의 경로</td>
                        <td>NVMe 인터페이스를 사용하는 SSD의 세 번째 파티션</td>
                    </tr>
                    <tr>
                        <td>VG</td>
                        <td>이 물리적 볼륨이 속한 볼륨 그룹의 이름</td>
                        <td>ubuntu-vg</td>
                    </tr>
                    <tr>
                        <td>Fmt</td>
                        <td>물리적 볼륨의 포맷</td>
                        <td>LVM2 (LVM의 두 번째 버전)</td>
                    </tr>
                        <tr>
                        <td>Attr</td>
                        <td>물리적 볼륨의 속성</td>
                        <td>a-- (볼륨이 활성 상태(active)임을 의미하며, 다른 속성들은 기본 설정 상태)</td>
                    </tr>
                    <tr>
                        <td>PSize</td>
                        <td>물리적 볼륨의 크기</td>
                        <td>928.46GB</td>
                    </tr>
                    <tr>
                        <td>PFree</td>
                        <td>물리적 볼륨의 사용 가능한 크기</td>
                        <td>828.46GB</td>
                    </tr>
            </tbody>
        </table>
        <list>
            <li>
                <p><control>/dev/nvme0n1p3</control> 파티션이 LVM을 사용하여 <control>ubuntu-vg</control>라는 볼륨 그룹의 일부로 구성되어 있음을 알 수 있다</p>
            </li>
        </list>
        <code-block lang="bash">
        sudo lsblk -f
        </code-block>
        <sub>조회 결과</sub>
        <code-block lang="bash">
        NAME                   FSTYPE      FSVER    LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINTS
        sda
        nvme0n1
        ├─nvme0n1p1            vfat        FAT32          917D-E823                                   1G     1% /boot/efi
        ├─nvme0n1p2            ext4        1.0            5bc61528-a75d-4c92-98fb-1c9a79fe43d9      1.5G    13% /boot
        └─nvme0n1p3            LVM2_member LVM2 001       iL1BHQ-ERxG-IcOt-2Lhe-habl-fwEb-SyyCle
        └─ubuntu--vg-ubuntu--lv            ext4        1.0            da834c60-6ff8-4458-a712-0fb35cd74914     79.9G    13% /
        </code-block>
    </tab>
</tabs>

### 논리 볼륨 (`/dev/mapper/ubuntu--vg-ubuntu--lv`) 확장하기 {id="ubuntu_partition_2_2"}
- `/dev/nvme0n1p3` 파티션은 `ubuntu-vg` 볼륨 그룹에 할당되어 있으며, 이 볼륨 그룹 내에는 828.46GB 가량의 미사용 공간이 존재함을 알 수 있다.
- 이 미사용 공간을 논리 볼륨에 할당하여 논리 볼륨의 크기를 확장하도록 한다
<procedure>
    <step>
        <p>논리 볼륨 확장</p>
        <list>
            <li>
                <p>시스템이 논리 볼륨을 사용 중이지 않은지 확인할 것</p>
                <code-block lang="bash">
                    sudo lsof /dev/ubuntu-vg/ubuntu-lv
                </code-block>
            </li>
            <li>
                <p>볼륨 그룹이 사용 가능한 공간을 모두 활용하려면 아래 명령어를 사용한다</p>
                <code-block lang="bash">
                    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
                </code-block>
            </li>
            <li>
                <p>논리 볼륨 정보를 확인한다</p>
                <code-block lang="bash">
                    sudo vgdisplay 
                </code-block>
                <sub>조회 결과</sub>
                <code-block lang="bash">
                    --- Logical volume ---
                    LV Path                /dev/ubuntu-vg/ubuntu-lv
                    LV Name                ubuntu-lv
                    VG Name                ubuntu-vg
                    LV UUID                zECVzc-JTMI-lBp1-q9rX-HMfU-0tEp-fKfF7R
                    LV Write Access        read/write
                    LV Creation host, time ubuntu-server, 2023-11-24 01:08:59 +0900
                    LV Status              available
                    # open                 1
                    LV Size                &lt; 928.46 GiB
                    Current LE             237685
                    Segments               1
                    Allocation             inherit
                    Read ahead sectors     auto
                    - currently set to     256
                    Block device           253:0
                </code-block>   
                <p>논리 볼륨의 크기(LV Size)가 100 GiB 에서 928.46 GiB 로 확장된 것을 확인할 수 있다</p>
            </li>
        </list>
    </step>
    <step>
        <p>파일 시스템 확장</p>
        <list>
            <li>
                <p>논리 볼륨의 크기를 확장한 후에는 파일 시스템도 새로운 크기에 맞게 확장해야 한다</p>
            </li>
            <li>
                <p>파일 시스템 확장을 위해서는 파일 시스템 정보를 미리 확인하여야 한다</p>
                <list>
                    <li>
                        <p>df 명령어 사용</p>
                        <code-block lang="bash">
                        sudo df -T
                        </code-block>
                        <sub>조회 결과</sub>
                        <code-block lang="bash">
                            Filesystem                        Type  1K-blocks     Used Available Use% Mounted on
                            tmpfs                             tmpfs   6567428     1640   6565788   1% /run
                            /dev/mapper/ubuntu--vg-ubuntu--lv ext4  102626232 13624692  83742276  14% /
                            tmpfs                             tmpfs  32837136        0  32837136   0% /dev/shm
                            tmpfs                             tmpfs      5120        0      5120   0% /run/lock
                            /dev/nvme0n1p2                    ext4    1992552   258940   1612372  14% /boot
                            /dev/nvme0n1p1                    vfat    1098632     6220   1092412   1% /boot/efi
                            tmpfs                             tmpfs   6567424        4   6567420   1% /run/user/1000
                        </code-block>
                    </li>
                    <li>
                        <p>lsblk 명령어 사용</p>
                        <code-block lang="bash">
                        sudo lsblk -f
                        </code-block>
                        <sub>조회 결과</sub>
                        <code-block lang="bash">
                            NAME                   FSTYPE      FSVER    LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINTS
                            sda
                            nvme0n1
                            ├─nvme0n1p1            vfat        FAT32          917D-E823                                   1G     1% /boot/efi
                            ├─nvme0n1p2            ext4        1.0            5bc61528-a75d-4c92-98fb-1c9a79fe43d9      1.5G    13% /boot
                            └─nvme0n1p3            LVM2_member LVM2 001       iL1BHQ-ERxG-IcOt-2Lhe-habl-fwEb-SyyCle
                              └─ubuntu--vg-ubuntu--lv            ext4        1.0            da834c60-6ff8-4458-a712-0fb35cd74914     79.9G    13% /
                        </code-block>
                    </li>
                </list>
                <p>`/dev/mapper/ubuntu--vg-ubuntu--lv` 논리 볼륨은 `ext4` 파일 시스템을 사용함을 확인</p>
            </li>
            <li>
                <p>ext4 파일 시스템을 사용한다면, resize2fs 명령을 사용한다</p>
                    <code-block lang="bash">
                    sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
                    </code-block>
                    <sub>조회 결과</sub>
                    <code-block lang="bash">
                        resize2fs 1.46.5 (30-Dec-2021)
                        Filesystem at /dev/ubuntu-vg/ubuntu-lv is mounted on /; on-line resizing required
                        old_desc_blocks = 13, new_desc_blocks = 117
                        The filesystem on /dev/ubuntu-vg/ubuntu-lv is now 243389440 (4k) blocks long.
                    </code-block>
            </li>
            <li>
                <p>파일 시스템의 크기를 확인</p>
                <code-block lang="bash">
                sudo df -h
                </code-block>
                <sub>조회 결과</sub>
                <code-block lang="bash">
                Filesystem                         Size  Used Avail Use% Mounted on
                tmpfs                              6.3G  1.7M  6.3G   1% /run
                /dev/mapper/ubuntu--vg-ubuntu--lv  914G   13G  863G   2% /
                tmpfs                               32G     0   32G   0% /dev/shm
                tmpfs                              5.0M     0  5.0M   0% /run/lock
                /dev/nvme0n1p2                     2.0G  253M  1.6G  14% /boot
                /dev/nvme0n1p1                     1.1G  6.1M  1.1G   1% /boot/efi
                tmpfs                              6.3G  4.0K  6.3G   1% /run/user/1000
                </code-block>
                <p>`/dev/mapper/ubuntu--vg-ubuntu--lv` 논리 볼륨의 크기가 100 GiB 에서 914 GiB 로 확장된 것을 확인할 수 있다</p>
            </li>
        </list>
    </step>
</procedure>

## 파티션 생성 {id="ubuntu_partition_3"}
### /dev/sda 의 파티션 생성 {id="ubuntu_partition_3_1"}
<procedure>
<step>
</step>
</procedure>

```bash
sudo fdisk /dev/sda
```
