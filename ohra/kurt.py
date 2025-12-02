import pygetm
print(pygetm.__file__)

print("before")
airsea = pygetm.airsea.FluxesFromMeteo(shortwave_method=pygetm.DOWNWARD_FLUX)
print("after")
print(type(airsea))
