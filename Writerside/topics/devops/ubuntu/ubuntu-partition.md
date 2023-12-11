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
        <p>파티션 생성</p>
        <code-block lang="bash">
            # 2TB 이하
            sudo fdisk /dev/sda
        </code-block>
    </step>
    <step>
        <p>물리적 볼륨 (Physical Volume, PV) 생성</p>
        <code-block lang="bash">
            sudo pvcreate /dev/sdaX
        </code-block>
        <sub><control>/dev/sdaX</control>는 신규로 생성한 파티션</sub>
    </step>
    <step>
        <p>볼륨 그룹 (Volume Group, VG) 생성</p>
        <code-block lang="bash">
            sudo vgcreate my_volume_group /dev/sdaX
        </code-block>
        <sub><control>my_volume_group</control>은 새로운 볼륨 그룹의 이름</sub>
    </step>
    <step>
        <p>논리 볼륨 생성 생성</p>
        <code-block lang="bash">
            sudo lvcreate -n my_logical_volume -L 100G my_volume_group
        </code-block>
        <sub><control>my_volume_group</control> 내에 100G 크기의 <control>my_logical_volume</control> 논리 볼륨을 생성</sub>
    </step>
    <step>
        <p>파일 시스템 생성 및 마운트</p>
        <code-block lang="bash">
            sudo mkfs.ext4 /dev/my_volume_group/my_logical_volume
        </code-block>
        <p>파일 시스템을 마운트 포인트에 마운트</p>
        <code-block lang="bash">
            sudo mkdir /mnt/hdd_1
            sudo mount /dev/my_volume_group/my_logical_volume /mnt/hdd_1
        </code-block>
    </step>
    <step>
        <p>결과 확인</p>
        <code-block lang="bash"> 
            df -h
        </code-block>
    </step>
    <step>
        <p>영구 마운트</p>
        <p>마운트는 재부팅 이후 다시 초기화 되기 때문에 설정파일에 명시해야 마운트를 유지할 수 있다</p>
        <code-block lang="bash">
            sudo vi /etc/fstab
        </code-block>
        <sub>입력</sub>
        <code-block lang="bash">
            # /mnt/hdd_1 on /dev/sda1
            /dev/sda1       /mnt/hdd_1      ext4    defaults        1       1
            # [파일_시스템_장치]  [마운트_포인트]  [파일_시스템_종류]  [특성]  [dump]  [파일체크]
        </code-block>
        <table>
            <thead>
                    <tr>
                        <th>파일_시스템_종류</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>ext</td>
                        <td>초기 리눅스에서 사용되었던 fs-type으로 지금은 사용하고 있지 않다.</td>
                    </tr>
                    <tr>
                        <td>ext2</td>
                        <td>지금도 사용하고 있는 fs-type으로 긴 파일명을 지원한다.</td>
                    </tr>
                    <tr>
                        <td>ext3</td>
                        <td>저널링 파일 시스템으로 ext2 에 비교해 파일 시스템 복구 기능 및 보안 기능을 향상시켰다.</td>
                    </tr>
                        <tr>
                        <td>ext4</td>
                        <td>ext3 다음 버전의 리눅스 표준 파일 시스템으로 16TB까지만 지원하던 ext3 보다 훨씬 큰 용량을 지원한다.</td>
                    </tr>
            </tbody>
        </table>
        <table>
            <thead>
                    <tr>
                        <th>특성</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>defaults</td>
                        <td>rw, nouser, auto, exec, suid 속성을 모두 가지며, 일반적인 파일 시스템에서 사용되는 속성이다</td>
                    </tr>
                    <tr>
                        <td>auto</td>
                        <td>부팅시 자동 마운트 가능하도록 한다</td>
                    </tr>
                    <tr>
                        <td>noauto</td>
                        <td>부팅시 자동 마운트가 되지 않도록 한다</td>
                    </tr>
                        <tr>
                        <td>exec</td>
                        <td>실행파일이 실행되는 것을 허용한다</td>
                    </tr>
                    <tr>
                        <td>noexec</td>
                        <td>실행파일이 실행되지 않도록 한다</td>
                    </tr>
                    <tr>
                        <td>suid</td>
                        <td>SetUID와 SetGID의 사용을 허용한다</td>
                    </tr>
                    <tr>
                        <td>nosuid</td>
                        <td>SetUID와 SetGID의 사용을 허용하지 않는다</td>
                    </tr>
                        <tr>
                        <td>ro</td>
                        <td>read only, 읽기 전용으로 마운트한다</td>
                    </tr>
                    <tr>
                        <td>rw</td>
                        <td>read write, 읽기, 쓰기 모두 가능하도록 마운트한다</td>
                    </tr>
                    <tr>
                        <td>user</td>
                        <td>일반 계정 사용자들도 모두 마운트할 수 있다</td>
                    </tr>
                    <tr>
                        <td>nouser</td>
                        <td>일반 계정 사용자들은 모두 마운트 할 수 없다</td>
                    </tr>
                    <tr>
                        <td>usrquota</td>
                        <td>개별 계정 사용자의 디스크 용량을 제한하기 위해 Quota를 설정한다</td>
                    </tr>
                    <tr>
                        <td>grpquota</td>
                        <td>그룹 별로 Quota 용량을 설정한다</td>
                    </tr>
            </tbody>
        </table>
        <table>
            <thead>
                    <tr>
                        <th>dump</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>0</td>
                        <td>백업 불가능한 파일 시스템</td>
                    </tr>
                    <tr>
                        <td>1</td>
                        <td>dump가 가능한 백업 가능한 파일 시스템</td>
                    </tr>
            </tbody>
        </table>
        <table>
            <thead>
                    <tr>
                        <th>파일체크</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>0</td>
                        <td>부팅시 파일 시스템 점검하지 않음</td>
                    </tr>
                    <tr>
                        <td>1</td>
                        <td>루트 파일 시스템으로 부팅시 파일 시스템을 점검한다</td>
                    </tr>
                    <tr>
                        <td>2</td>
                        <td>루트 파일 시스템 이외의 파일시스템으로서 부팅시 파일 시스템을 점검한다.</td>
                    </tr>
            </tbody>
        </table>
    </step>
</procedure>

### /dev/sda 의 파티션 생성 (2TiB 이상) {collapsible="true"}
<procedure>
    <step>
        <p>파티션 생성 전</p>
        <list>
        <li>
            <p>기본 MBR(Master Boot Record)은 2TB 이상의 파티션을 지원하지 않는다.</p>
        </li>
        <li>
            <p>2TB 이상의 파티션 생성을 위해서는 GPT(GUID Partition Table) 디스크 레이블을 사용해야 한다.</p>
        </li>
        </list>
</step>
<step>
        <p>디스크 포맷 확인</p>
        <list>
        <li>
            <p>parted 명령어</p>
            <code-block lang="bash">
                # 디스크가 GPT로 포맷되어 있는지 확인 (parted)
                sudo parted /dev/sda print
            </code-block>
            <sub>조회 결과</sub>
            <code-block lang="bash">
                Error: /dev/sda: unrecognised disk label
                Model: ATA WDC WD40EZAX-00C (scsi)
                Disk /dev/sda: 4001GB
                Sector size (logical/physical): 512B/4096B
                Partition Table: unknown
                Disk Flags:
            </code-block>
        </li>
        <li>
            <p>gdisk 명령어</p>
            <code-block lang="bash">
                # 디스크가 GPT로 포맷되어 있는지 확인 (gdisk)
                sudo gdisk -l /dev/sda
            </code-block>
            <sub>조회 결과</sub>
            <code-block lang="bash">
                GPT fdisk (gdisk) version 1.0.8
                ---
                Partition table scan:
                MBR: protective
                BSD: not present
                APM: not present
                GPT: not present
            </code-block>
        </li>
        </list>
        <p>GPT 가 아니라면 해당 디스크의 모든 데이터를 백업한 뒤 재포맷 하여야 한다</p>
    </step>
    <step> 
        <p>디스크 포맷 설정</p>
        <list>
        <li>
            <p>GPT 파티션 적용</p>
            <code-block lang="bash">
                sudo parted /dev/sda
            </code-block>  
            <code>mklabel gpt</code><sub>입력</sub>
            <code-block lang="bash">
                GNU Parted 3.4
                Using /dev/sda
                Welcome to GNU Parted! Type 'help' to view a list of commands.
                (parted) mklabel gpt
                (parted) quit
            </code-block>
        </li>
        <li>
            <p>포맷 확인</p>
            <code-block lang="bash">
                # 디스크가 GPT로 포맷되어 있는지 확인 (parted)
                sudo parted /dev/sda print
            </code-block>
            <code-block lang="bash">
                Model: ATA WDC WD40EZAX-00C (scsi)
                Disk /dev/sda: 4001GB
                Sector size (logical/physical): 512B/4096B
                Partition Table: gpt
                Disk Flags:
                ---
                Number  Start  End  Size  File system  Name  Flags
            </code-block>
            ---
            <code-block lang="bash">
                # 디스크가 GPT로 포맷되어 있는지 확인 (gdisk)
                sudo gdisk -l /dev/sda
            </code-block>
            <code-block lang="bash">
                GPT fdisk (gdisk) version 1.0.8
                ---
                Partition table scan:
                MBR: protective
                BSD: not present
                APM: not present
                GPT: present
                ---
                Found valid GPT with protective MBR; using GPT.
                Disk /dev/sda: 7814037168 sectors, 3.6 TiB
                Model: WDC WD40EZAX-00C
                Sector size (logical/physical): 512/4096 bytes
                Disk identifier (GUID): 99C334F5-73F4-435D-8F00-F4328E440125
                Partition table holds up to 128 entries
                Main partition table begins at sector 2 and ends at sector 33
                First usable sector is 34, last usable sector is 7814037134
                Partitions will be aligned on 2048-sector boundaries
                Total free space is 7814037101 sectors (3.6 TiB)
                Number  Start (sector)    End (sector)  Size       Code  Name
            </code-block>
        </li>
        </list>
    </step>
    <step>
        <p>파티션 생성</p>
        <code-block lang="bash">
            sudo parted /dev/sda mkpart primary 0% 100%
        </code-block>
        <p>primary는 파티션 타입이며, 파티션의 처음과 끝을 지정한다</p>
        <p>이후 파티션 명을 확인한다</p>
        <code-block lang="bash">
        sudo fdisk -l
        </code-block>
        <sub>조회 결과</sub>
        <code-block lang="bash">
            Disk /dev/nvme0n1: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
            Disk model: CT1000P3SSD8
            Units: sectors of 1 * 512 = 512 bytes
            Sector size (logical/physical): 512 bytes / 512 bytes
            I/O size (minimum/optimal): 512 bytes / 512 bytes
            Disklabel type: gpt
            Disk identifier: 7868E63D-D3AC-4727-B8EE-7186B5EF7F64
            ---
            Device           Start        End    Sectors   Size Type
            /dev/nvme0n1p1    2048    2203647    2201600     1G EFI System
            /dev/nvme0n1p2 2203648    6397951    4194304     2G Linux filesystem
            /dev/nvme0n1p3 6397952 1953521663 1947123712 928.5G Linux filesystem
            ---
            ---
            Disk /dev/sda: 3.64 TiB, 4000787030016 bytes, 7814037168 sectors
            Disk model: WDC WD40EZAX-00C
            Units: sectors of 1 * 512 = 512 bytes
            Sector size (logical/physical): 512 bytes / 4096 bytes
            I/O size (minimum/optimal): 4096 bytes / 4096 bytes
            Disklabel type: gpt
            Disk identifier: 99C334F5-73F4-435D-8F00-F4328E440125
            ---
            Device     Start        End    Sectors  Size Type
            /dev/sda1   2048 7814035455 7814033408  3.6T Linux filesystem
            ---
            ---
            Disk /dev/mapper/ubuntu--vg-ubuntu--lv: 928.46 GiB, 996923146240 bytes, 1947115520 sectors
            Units: sectors of 1 * 512 = 512 bytes
            Sector size (logical/physical): 512 bytes / 512 bytes
            I/O size (minimum/optimal): 512 bytes / 512 bytes
        </code-block>
        <p><control>/dev/sda1</control> 파티션이 신규 생성되었음을 확인할 수 있다</p>
    </step>
     <step>
        <p>파일 시스템 생성</p>
        <code-block lang="bash">
            sudo mkfs.ext4 /dev/sda1
        </code-block>
        <p>파일 시스템은 일반적으로 <control>ext4</control>를 사용한다</p>
        <sub>처리 결과</sub>
        <code-block lang="bash">
            mke2fs 1.46.5 (30-Dec-2021)
            Creating filesystem with 976754176 4k blocks and 244195328 inodes
            Filesystem UUID: ae443103-d309-4e21-ac24-5744a20db2a2
            Superblock backups stored on blocks:
                    32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
                    4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
                    102400000, 214990848, 512000000, 550731776, 644972544
            ---
            Allocating group tables: done
            Writing inode tables: done
            Creating journal (262144 blocks): # 여기서 Enter
            done
            Writing superblocks and filesystem accounting information: done
        </code-block>
    </step>
    <step>
        <p>마운트 및 사용</p>
        <code-block lang="bash">
            sudo mkdir /mnt/hdd_1
            sudo mount /dev/sda1 /mnt/hdd_1
        </code-block>
    </step>
        <step>
        <p>결과 확인</p>
        <code-block lang="bash"> 
            df -h
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
            /dev/sda1                          3.6T   28K  3.4T   1% /mnt/hdd_1
        </code-block>
    </step>
    <step>
        <p>영구 마운트</p>
        <p>마운트는 재부팅 이후 다시 초기화 되기 때문에 설정파일에 명시해야 마운트를 유지할 수 있다</p>
        <code-block lang="bash">
            sudo vi /etc/fstab
        </code-block>
        <sub>입력</sub>
        <code-block lang="bash">
            # /mnt/hdd_1 on /dev/sda1
            /dev/sda1       /mnt/hdd_1      ext4    defaults        1       1
            # [파일_시스템_장치]  [마운트_포인트]  [파일_시스템_종류]  [특성]  [dump]  [파일체크]
        </code-block>
        <table>
            <thead>
                    <tr>
                        <th>파일_시스템_종류</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>ext</td>
                        <td>초기 리눅스에서 사용되었던 fs-type으로 지금은 사용하고 있지 않다.</td>
                    </tr>
                    <tr>
                        <td>ext2</td>
                        <td>지금도 사용하고 있는 fs-type으로 긴 파일명을 지원한다.</td>
                    </tr>
                    <tr>
                        <td>ext3</td>
                        <td>저널링 파일 시스템으로 ext2 에 비교해 파일 시스템 복구 기능 및 보안 기능을 향상시켰다.</td>
                    </tr>
                        <tr>
                        <td>ext4</td>
                        <td>ext3 다음 버전의 리눅스 표준 파일 시스템으로 16TB까지만 지원하던 ext3 보다 훨씬 큰 용량을 지원한다.</td>
                    </tr>
            </tbody>
        </table>
        <table>
            <thead>
                    <tr>
                        <th>특성</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>defaults</td>
                        <td>rw, nouser, auto, exec, suid 속성을 모두 가지며, 일반적인 파일 시스템에서 사용되는 속성이다</td>
                    </tr>
                    <tr>
                        <td>auto</td>
                        <td>부팅시 자동 마운트 가능하도록 한다</td>
                    </tr>
                    <tr>
                        <td>noauto</td>
                        <td>부팅시 자동 마운트가 되지 않도록 한다</td>
                    </tr>
                        <tr>
                        <td>exec</td>
                        <td>실행파일이 실행되는 것을 허용한다</td>
                    </tr>
                    <tr>
                        <td>noexec</td>
                        <td>실행파일이 실행되지 않도록 한다</td>
                    </tr>
                    <tr>
                        <td>suid</td>
                        <td>SetUID와 SetGID의 사용을 허용한다</td>
                    </tr>
                    <tr>
                        <td>nosuid</td>
                        <td>SetUID와 SetGID의 사용을 허용하지 않는다</td>
                    </tr>
                        <tr>
                        <td>ro</td>
                        <td>read only, 읽기 전용으로 마운트한다</td>
                    </tr>
                    <tr>
                        <td>rw</td>
                        <td>read write, 읽기, 쓰기 모두 가능하도록 마운트한다</td>
                    </tr>
                    <tr>
                        <td>user</td>
                        <td>일반 계정 사용자들도 모두 마운트할 수 있다</td>
                    </tr>
                    <tr>
                        <td>nouser</td>
                        <td>일반 계정 사용자들은 모두 마운트 할 수 없다</td>
                    </tr>
                    <tr>
                        <td>usrquota</td>
                        <td>개별 계정 사용자의 디스크 용량을 제한하기 위해 Quota를 설정한다</td>
                    </tr>
                    <tr>
                        <td>grpquota</td>
                        <td>그룹 별로 Quota 용량을 설정한다</td>
                    </tr>
            </tbody>
        </table>
        <table>
            <thead>
                    <tr>
                        <th>dump</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>0</td>
                        <td>백업 불가능한 파일 시스템</td>
                    </tr>
                    <tr>
                        <td>1</td>
                        <td>dump가 가능한 백업 가능한 파일 시스템</td>
                    </tr>
            </tbody>
        </table>
        <table>
            <thead>
                    <tr>
                        <th>파일체크</th>
                        <th>옵션</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>0</td>
                        <td>부팅시 파일 시스템 점검하지 않음</td>
                    </tr>
                    <tr>
                        <td>1</td>
                        <td>루트 파일 시스템으로 부팅시 파일 시스템을 점검한다</td>
                    </tr>
                    <tr>
                        <td>2</td>
                        <td>루트 파일 시스템 이외의 파일시스템으로서 부팅시 파일 시스템을 점검한다.</td>
                    </tr>
            </tbody>
        </table>
    </step>
</procedure>

## 번외 {id="ubuntu_partition_99"}
### /dev 디렉터리는 무엇인가? {id="ubuntu_partition_99_1"}
- Linux는 전통적으로 모든 것을 읽거나 쓸 수 있는 파일이나 디렉터리로 취급한다
  - /dev 는 모든 장치 파일이 포함된 루트 폴더의 디렉터리
  - 시스템은 설치 중에 이러한 파일을 생성하며 부팅 프로세스 중에 사용할 수 있어야 한다
- /dev 디렉토리 에서 장치 파일을 식별할 수 있는 보다 상세하고 직접적인 방법은 장치의 주 번호와 부 번호를 사용하는 것이다
  - 디스크 장치의 주 번호는 8이며 이를 SCSI 블록 장치 로 지정한다
  - SCSI 하위 시스템 은 모든 PATA 및 SATA 하드 드라이브를 관리한다
  - SCSI 는 마이크로프로세서로 제어되는 스마트 버스이며 컴퓨터에 최대 15개의 주변 장치를 추가할 수 있다
  - 이러한 장치에는 하드 드라이브, 스캐너, USB, 프린터 및 기타 여러 장치가 포함된다
  - 각 이름은 sd[az] 로 지정되며 이전에는 hd[az] (하드드라이브) 로 지정된 바 있다

- /dev/sda
    - /dev/sd[az]는 하드 드라이브를 의미한다
    - Linux는 발견된 첫 번째 하드 디스크를 가져와서 sda 값을 지정한다
    - 이후 하드 디스크는 sdb, sdc, ... 으로 알파벳 순으로 등록된다
    - sda[1-15] 의 경우 sda 하드 드라이브의 파티션에 따라 순차 등록된다
    - 단일 하드 디스크에는 최대 15개의 파티션만 가질 수 있다
```Bash
$ ls -l /dev | grep "sda"
brw-rw----  1 root disk        8,   0  Apr 29 22:33 sda
brw-rw----  1 root disk        8,   1  Apr 29 22:33 sda1
brw-rw----  1 root disk        8,   2  Apr 29 22:33 sda2
brw-rw----  1 root disk        8,   3  Apr 29 22:33 sda3
brw-rw----  1 root disk        8,   4  Apr 29 22:33 sda4
brw-rw----  1 root disk        8,   5  Apr 29 22:33 sda5
brw-rw----  1 root disk        8,   6  Apr 29 22:33 sda6
```