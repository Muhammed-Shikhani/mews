#!/usr/bin/env python



import datetime
from pathlib import Path
from typing import Optional
import numpy as np
import xarray as xr

import cftime

import pygetm



setup = "ohra"
nz = 20
ddu = 1.5
ddl = 0.5
Dgamma = 15.0
timestep = 0.8
use_adaptive = False
light_A = 0.58
light_kc1 = 2.5
light_kc2 = 1.0

def create_domain(
    runtype: int,
    rivers: bool,
    **kwargs,
):
    import netCDF4
    import glob
    import os

    with netCDF4.Dataset(args.bathymetry_file) as nc:
        nc.set_auto_mask(False)
        domain = pygetm.domain.create_cartesian(
            nc["x"][:],
            nc["y"][:],
            lon=nc["lon"],
            lat=nc["lat"],
            H=nc[args.bathymetry_name][:, :],
            mask=np.where(nc[args.bathymetry_name][...] == -9999.0, 0, 1),
            z0=0.01,
        )
    domain.limit_velocity_depth()
    domain.cfl_check()
    domain.mask_shallow(1.0)
#    if rivers:
#       river_list = []
#       # Inflows
#       for river in glob.glob("Rivers/Inflow_*.nc"):
#           name = os.path.basename(river)
#           name = name.replace("Inflow_", "").replace(".nc", "")
#           with netCDF4.Dataset(river) as r:
#               lon = r["lon"][:]
#               lat = r["lat"][:]
#               river_list.append(
#                   domain.rivers.add_by_location(
#                       name,
#                       float(lon),
#                       float(lat),
#                       coordinate_type=pygetm.CoordinateType.LONLAT
#                   )
#               )
       # Outflows
 #      for river in glob.glob("Rivers/Outflow.nc"):
 #          name = os.path.basename(river)
 #          name = name.replace("Outflow", "").replace(".nc", "")
 #          with netCDF4.Dataset(river) as r:
 #              lon = r["lon"][:]
 #              lat = r["lat"][:]
 #              river_list.append(
 #                  domain.rivers.add_by_location(
 #                      name, float(lon), float(lat), coordinate_type=pygetm.CoordinateType.LONLAT
 #                  )
 #             )

    return domain


# Initialize airsea with DOWNWARD_FLUX for SSRD


def create_simulation(
    domain: pygetm.domain.Domain,
    runtype: pygetm.RunType,
    **kwargs,
) -> pygetm.simulation.Simulation:
    import numpy as np
    import pandas as pd
    import os

    global use_adaptive
    if True:
        internal_pressure = pygetm.internal_pressure.ShchepetkinMcwilliams()
    else:
        internal_pressure = pygetm.internal_pressure.BlumbergMellor()

    if True:
        airsea = pygetm.airsea.FluxesFromMeteo(shortwave_method=pygetm.DOWNWARD_FLUX )

    if True:
        vertical_coordinates = pygetm.vertical_coordinates.GVC(
            nz, ddl=ddl, ddu=ddu, Dgamma=Dgamma, gamma_surf=True
        )
    elif False:
        try:
            use_adaptive = True
            vertical_coordinates = pygetm.vertical_coordinates.Adaptive(
                nz,
                timestep,
                cnpar=1.0,
                ddu=ddu,
                ddl=ddl,
                gamma_surf=True,
                Dgamma=Dgamma,
                csigma=0.001,
                cgvc=-0.001,
                hpow=3,
                chsurf=-0.001,
                hsurf=1.5,
                chmidd=-0.1,
                hmidd=0.5,
                chbott=-0.001,
                hbott=1.5,
                cneigh=-0.1,
                rneigh=0.25,
                decay=2.0 / 3.0,
                # cNN=1.0,
                cNN=0.1,
                drho=0.2,
                cSS=-1.0,
                dvel=0.1,
                chmin=0.1,
                hmin=0.5,
                nvfilter=1,
                vfilter=0.1,
                nhfilter=1,
                hfilter=0.2,
                split=1,
                timescale=3.0 * 3600.0,
            )
        except:
            print("Error: can not initialize Adaptive-coordinates")
            quit()
    else:
        vertical_coordinates = pygetm.vertical_coordinates.Sigma(nz, ddl=ddl, ddu=ddu)

    final_kwargs = dict(
        advection_scheme=pygetm.AdvectionScheme.SUPERBEE,
        # gotm=os.path.join(setup_dir, "gotmturb.nml"),
        airsea=airsea,
        internal_pressure=internal_pressure,
        vertical_coordinates=vertical_coordinates,
        delay_slow_ip=True
     #   Dmin = 3
    )
    final_kwargs.update(kwargs)
    sim = pygetm.Simulation(domain, runtype=runtype, gotm = "gotm.yaml", **final_kwargs)
   # sim = pygetm.Simulation(domain, runtype=runtype, gotm = "gotm.yaml",  **final_kwargs)
  #  sim = pygetm.Simulation(domain, runtype=runtype, fabm = "fabm-selmaprotbas.yaml", **final_kwargs)
    if sim.runtype < pygetm.RunType.BAROCLINIC:
        sim.sst = sim.airsea.t2m
    if sim.runtype == pygetm.RunType.BAROCLINIC:
        sim.radiation.set_jerlov_type(pygetm.Jerlov.Type_II)
        sim.radiation.A.fill(light_A)
        sim.radiation.kc1.fill(light_kc1)
        sim.radiation.kc2.fill(light_kc2)


    if not args.load_restart and sim.runtype == pygetm.RunType.BAROCLINIC:
        if True:
           sim.temp.set(4)
           sim.salt.set(0.1)
        else:
            print("Read froom files")
            # sim.salt.set(
            # pygetm.input.from_nc(
            #    os.path.join(args.setup_dir, "Input/initialConditions.nc"), "salt"
            # ),
            # on_grid=True,
        # )
        sim.density.convert_ts(sim.salt, sim.temp)
        sim.temp[..., sim.T.mask == 0] = pygetm.constants.FILL_VALUE
        sim.salt[..., sim.T.mask == 0] = pygetm.constants.FILL_VALUE

    ERA_path = "ERA5/era5_????.nc"
    sim.airsea.u10.set(pygetm.input.from_nc(ERA_path, "u10")*1.2)
    sim.airsea.v10.set(pygetm.input.from_nc(ERA_path, "v10")*1.2)
    sim.airsea.t2m.set(pygetm.input.from_nc(ERA_path, "t2m") - 273.15)
    sim.airsea.d2m.set(pygetm.input.from_nc(ERA_path, "d2m") - 273.15)
    sim.airsea.sp.set(pygetm.input.from_nc(ERA_path, "sp"))
    sim.airsea.tcc.set(pygetm.input.from_nc(ERA_path, "tcc"))
    ERA_path = "ERA5/precip_????.nc"
    sim.airsea.tp.set(pygetm.input.from_nc(ERA_path, "tp") / 3600.0)
    if sim.airsea.shortwave_method == pygetm.DOWNWARD_FLUX:
        ERA_path = "ERA5/ssrd_2021.nc"
        sim.airsea.swr_downwards.set(
            pygetm.input.from_nc(ERA_path, "ssrd")* ( 0.8/3600.0 )
        )
 #   for river in sim.rivers.values():
 #      if "outflow" in river.name:
 #          ### Outflow
 #          river.flow.set(pygetm.input.from_nc(f"Rivers/Outflow_file_{river.name}.nc", "q"))
 #      else:
 #          ### Inflow
 #          river.flow.set(pygetm.input.from_nc(f"Rivers/Inflow_file_{river.name}.nc", "q"))         
 #          river["temp"].follow_target_cell = False #(True makes it use the value from the basin)
 #          river["temp"].set(pygetm.input.from_nc(f"Rivers/Inflow_file_{river.name}.nc", "Temp"))
           # Nutrients
         #  river["selmaprotbas_po"].follow_target_cell = False #(True makes it use the value from the basin)
         #  river["selmaprotbas_po"].set(pygetm.input.from_nc(f"Rivers/Inflow_file_{river.name}.nc", "PO4"))  
         #  river["selmaprotbas_nn"].follow_target_cell = False
         #  river["selmaprotbas_nn"].set(pygetm.input.from_nc(f"Rivers/Inflow_file_{river.name}.nc", "NO3"))
         #  river["selmaprotbas_dd_p"].follow_target_cell = False
         #  river["selmaprotbas_dd_p"].set(pygetm.input.from_nc(f"Rivers/Inflow_file_{river.name}.nc", "dd_P"))
    
   # sim["age_age_of_water"].river_follow[:] = False # By default, precipitation also has age 0
    return sim

def create_output(
    output_dir: str,
    sim: pygetm.simulation.Simulation,
    **kwargs,
):
    sim.logger.info("Setting up output")

    path = Path(output_dir, "meteo.nc")
    output = sim.output_manager.add_netcdf_file(
        str(path),
        interval=datetime.timedelta(hours=1),
        sync_interval=None,
    )
    output.request(
        "u10",
        "v10",
        "sp",
        "t2m",
        "tcc",
        "tp",
  #      "ssrd",
    )

    path = Path(output_dir, setup + "_2d.nc")
    output = sim.output_manager.add_netcdf_file(
        str(path),
        interval=datetime.timedelta(hours=24),
        sync_interval=None,
    )
    output.request("Ht", "zt","Dt", "u1", "v1", "tausxu", "tausyv")
    if args.debug_output:
        output.request("maskt", "masku", "maskv")
        output.request("U", "V")
        # output.request("Du", "Dv", "dpdx", "dpdy", "z0bu", "z0bv", "z0bt")
        # output.request("ru", "rru", "rv", "rrv")

    if sim.runtype > pygetm.RunType.BAROTROPIC_2D:
        path = Path(output_dir, setup + "_3d.nc")
        output = sim.output_manager.add_netcdf_file(
            str(path),
            interval=datetime.timedelta(hours=6),
            sync_interval=None,
        )
    output.request("Ht", "uk", "vk", "ww", "SS", "num")
    if args.debug_output:
        #output.request("fpk", "fqk", "advpk", "advqk")  # 'diffpk', 'diffqk')
        output.request("fpk", "fqk","advpk", "advqk")  # 'diffpk', 'diffqk')


    if sim.runtype == pygetm.RunType.BAROCLINIC:
        output.request("temp", "salt", "rho", "swr", "NN", "rad", "sst", "hnt", "nuh")
        if args.debug_output:
            output.request("idpdx", "idpdy")
        if use_adaptive:
            output.request("nug", "ga", "dga")

   # if sim.fabm:
   #     output.request( "selmaprotbas_po", "total_chlorophyll_calculator_result", "selmaprotbas_o2")


def run(
    sim: pygetm.simulation.Simulation,
    start: cftime.datetime,
    stop: cftime.datetime,
    dryrun: bool = False,
    **kwargs,
):
    if dryrun:
        print(f"")
        print(f"Making a dryrun - skipping sim.advance()")
        print(f"")
    else:
        sim.start(
            simstart,
            timestep=timestep,
            split_factor=20,
            **kwargs,
        )
        debug_time = datetime.datetime.strptime(
            "2022-07-15 00:00:00", "%Y-%m-%d %H:%M:%S"
        )
        while sim.time < simstop:
            if sim.time < debug_time:
                x= False
            else:
                x = True
            sim.advance(check_finite=x)
        sim.finish()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("start", help="simulation start time - yyyy-mm-dd hh:mi:ss")
    parser.add_argument("stop", help="simulation stop time - yyyy-mm-dd hh:mi:ss")
    parser.add_argument(
        "--setup_dir",
        type=Path,
        help="Path to configuration files - not used yet",
        default=".",
    )

    parser.add_argument(
        "--bathymetry_file",
        type=str,
        help="Name of bathymetry file",
    #    default="Bathymetry/bathymetry_smoothed_local_v5.nc",
        default="Bathymetry/bathymetry.nc",
    )

    parser.add_argument(
        "--bathymetry_name",
        type=str,
        help="Name of bathymetry variable",
    #    default="bathymetry_rx01_local_v",
        default="bathymetry",
    )

    parser.add_argument(
        "--output_dir", type=str, help="Path to save output files", default="."
    )

    parser.add_argument(
        "--runtype",
        type=int,
        choices=(pygetm.BAROTROPIC_2D, pygetm.BAROTROPIC_3D, pygetm.BAROCLINIC),
        help="Run type",
        default=pygetm.BAROCLINIC,
    )
    parser.add_argument(
        "--no_rivers", action="store_false", dest="rivers", help="No river input"
    )
    parser.add_argument(
        "--no_output",
        action="store_false",
        dest="output",
        help="Do not save any results to NetCDF",
    )
    parser.add_argument(
        "--debug_output",
        action="store_true",
        help="Save additional variables for debugging",
    )
    parser.add_argument("--save_restart", help="File to save restart to")
    parser.add_argument("--load_restart", help="File to load restart from")
    parser.add_argument("--profile", help="File to save profiling report to")
    parser.add_argument("--dryrun", action="store_true", help="Do a dry run")
    parser.add_argument(
        "--plot_domain", action="store_true", help="Plot the calculation domain"
    )
    args = parser.parse_args()

    if args.output_dir != ".":
        p = Path(args.output_dir)
        if not p.is_dir():
            print(f"Folder {args.output_dir} does not exist - create and run again")
            exit()

    domain = create_domain(args.runtype, args.rivers)

    sim = create_simulation(domain, args.runtype)

    # for plot options see:
    # https://github.com/BoldingBruggeman/getm-rewrite/blob/fea843cbc78bd7d166bdc5ec71c8d3e3ed080a35/python/pygetm/domain.py#L1943
    if args.plot_domain:
        f = domain.plot(show_mesh=False, show_subdomains=False)
        if f is not None:
            f.savefig("domain_mesh.png")
        f = domain.plot(show_mesh=False, show_mask=True)
        if f is not None:
            f.savefig("domain_mask.png")

    if args.output and not args.dryrun:
        create_output(args.output_dir, sim)

    if args.save_restart and not args.dryrun:
        sim.output_manager.add_restart(args.save_restart)

    if args.load_restart and not args.dryrun:
        simstart = sim.load_restart(args.load_restart)

    simstart = datetime.datetime.strptime(args.start, "%Y-%m-%d %H:%M:%S")
    simstop = datetime.datetime.strptime(args.stop, "%Y-%m-%d %H:%M:%S")
    profile = setup if args.profile is not None else None
    run(
        sim,
        simstart,
        simstop,
        dryrun=args.dryrun,
        report=datetime.timedelta(hours=3),
        report_totals=datetime.timedelta(days=7),
        profile=profile,
    )
