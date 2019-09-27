import subprocess
from pathlib import Path

def test_loopback():
    # testbench location
    signals = 'src/signals/fpga'
    top = 'src/top/fpga/top.sv'

    # library locations
    libs = []
    libs.append('src/loopback/fpga/loopback.sv')
    libs.append('src/tx/fpga/tx.sv')
    libs.append('src/vio/beh/vio.sv')
    libs.append('src/mmcm/beh/mmcm.sv')
    libs.append('src/time_manager/fpga/time_manager.sv')
    libs.append('src/clk_gen/fpga/clk_gen.sv')
    libs.append('src/clk_drv/fpga/clk_drv.sv')
    libs.append('src/prbs21/fpga/prbs21.sv')
    libs.append('src/chan/fpga/chan.sv')
    libs.append('src/tb/syn/tb.sv')
    libs.append('src/rx/syn/rx.sv')
    libs.append('src/rx_cmp/fpga/rx_cmp.sv')
    libs.append('src/BUFG/beh/BUFG.sv')

    # resolve paths
    signals = Path(signals).resolve()
    top = Path(top).resolve()
    libs = [Path(lib).resolve() for lib in libs]

    # construct the command
    args = []
    args += ['xrun']
    args += ['-timescale', '1s/1fs']
    args += [f'{top}']
    args += ['-top', 'top']
    args += [f'+incdir+{signals}']
    for lib in libs:
        args += ['-v', f'{lib}']

    # set up build dir     
    cwd = Path('tests/build_fpga')
    cwd.mkdir(exist_ok=True)

    # run the simulation
    result = subprocess.run(args, cwd=cwd)
    assert result.returncode == 0

if __name__ == '__main__':
    test_loopback()
