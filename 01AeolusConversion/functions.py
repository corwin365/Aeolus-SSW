#!/usr/bin/env python3
"""
Aeolus Functions file
================================================================================
--------------------------------------------------------------------------------
----------------------------No version control----------------------------------
--------------------------------------------------------------------------------
================================================================================
Provides functions for all files for the Aeolus project
================================================================================
"""

# Imports
import netCDF4 as nc
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as dates
import os
import errno
from datetime import timedelta, datetime, date
from scipy.interpolate import griddata
import calendar
import time
import coda
import sys
sys.path.append('/home/tpb38/PhD/Bath/')
from phdfunctions import *


def load_hdr_tags(hdr):
	# Open HDR file
	pfhdr = coda.open(hdr)
	
	# Get field names and fetch data according to the ICD document:
	# L-2B/2C_I/O_Data_Definitions
	Earth_Explorer_Header = coda.fetch(pfhdr, 'Earth_Explorer_Header')
	
	# Fixed_Header
	Fixed_Header = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Fixed_Header')
	File_Name = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/File_Name')
	File_Description = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/File_Description')
	Notes = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Notes')
	Mission = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Mission')
	File_Class = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/File_Class')
	File_Type = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/File_Type')
	File_Version = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/File_Version')
	
	#	 Validity_Period:
	Validity_Period = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Validity_Period')
	Validity_Start = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Validity_Period/Validity_Start')
	Validity_Stop = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Validity_Period/Validity_Stop')
	
	#	 Source:
	Source = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Source')
	System = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Source/System')
	Creator = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Source/Creator')
	Creator_Version = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Source/Creator_Version')
	Creation_Date = coda.fetch(pfhdr, 'Earth_Explorer_Header/Fixed_Header/Source/Creation_Date')
	
	# Variable_Header
	Variable_Header = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header')
	
	#	 Main_Product_Header
	Main_Product_Header = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header')
	Product = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Product')
	Proc_Stage = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Proc_Stage')
	Ref_Doc = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Ref_Doc')
	Acquisition_Station = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Acquisition_Station')
	Proc_Center = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Proc_Center')
	Proc_Time = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Proc_Time')
	Software_Ver = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Software_Ver')
	Baseline = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Baseline')
	Sensing_Start = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Sensing_Start')
	Sensing_Stop = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Sensing_Stop')
	Phase = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Phase')
	Cycle = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Cycle')
	Rel_Orbit = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Rel_Orbit')
	Abs_Orbit = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Abs_Orbit')
	State_Vector_Time = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/State_Vector_Time')
	Delta_UT1 = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Delta_UT1')
	X_Position = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/X_Position')
	Y_Position = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Y_Position')
	Z_Position = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Z_Position')
	X_Velocity = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/X_Velocity')
	Y_Velocity = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Y_Velocity')
	Z_Velocity = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Z_Velocity')
	Vector_Source = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Vector_Source')
	Utc_Sbt_Time = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Utc_Sbt_Time')
	Sat_Binary_Time = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Sat_Binary_Time')
	Clock_Step = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Clock_Step')
	Leap_Utc = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Leap_Utc')
	Gps_Utc_Time_Difference = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Gps_Utc_Time_Difference')
	Leap_Sign = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Leap_Sign')
	Leap_Err = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Leap_Err')
	Product_Err = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Product_Err')
	Tot_Size = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Tot_Size')
	Sph_Size = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Sph_Size')
	Num_Dsd = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Num_Dsd')
	Dsd_Size = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Dsd_Size')
	Num_Data_Sets = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Main_Product_Header/Num_Data_Sets')
	
	#	 Specific_Product_Header
	Specific_Product_Header = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header')
	Sph_Descriptor = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Sph_Descriptor')
	NumMeasurements = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumMeasurements')
	NumMieGroups = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumMieGroups')
	NumRayleighGroups = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumRayleighGroups')
	NumMieWindResults = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumMieWindResults')
	NumRayleighWindResults = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumRayleighWindResults')
	NumMieProfiles = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumMieProfiles')
	NumRayleighProfiles = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumRayleighProfiles')
	NumAMDprofiles = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/NumAMDprofiles')
	Intersect_Start_Lat = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Intersect_Start_Lat')
	Intersect_Start_Long = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Intersect_Start_Long')
	Intersect_Stop_Lat = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Intersect_Stop_Lat')
	Intersect_Stop_Long = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Intersect_Stop_Long')
	Sat_Track = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Sat_Track')
	
	#		 Counts
	List_of_Valid_Mie_Profile_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_Mie_Profile_Counts')
	Valid_Mie_Profile_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_Mie_Profile_Counts/Valid_Mie_Profile_Count')
	List_of_Valid_Rayleigh_Profile_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_Rayleigh_Profiles_Counts')
	Valid_Rayleigh_Profile_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_Rayleigh_Profiles_Counts/Valid_Rayleigh_Profile_Count')
	List_of_Invalid_Mie_Profile_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_Mie_Profile_Counts')
	Invalid_Mie_Profile_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_Mie_Profile_Counts/Invalid_Mie_Profile_Count')
	List_of_Invalid_Rayleigh_Profile_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_Rayleigh_Profile_Counts')
	Invalid_Rayleigh_Profile_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_Rayleigh_Profile_Counts/Invalid_Rayleigh_Profile_Count')
	Num_Profiles_Surface_Mie = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Num_Profiles_Surface_Mie')
	Num_Profiles_Surface_Ray = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/Num_Profiles_Surface_Ray')
	List_of_Valid_L2B_Mie_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2B_Mie_Wind_Counts')
	Valid_L2B_Mie_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2B_Mie_Wind_Counts/Valid_L2B_Mie_Wind_Count')
	List_of_Valid_L2B_Rayleigh_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2B_Rayleigh_Wind_Counts')
	Valid_L2B_Rayleigh_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2B_Rayleigh_Wind_Counts/Valid_L2B_Rayleigh_Wind_Count')
	List_of_Invalid_L2B_Mie_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2B_Mie_Wind_Counts')
	Invalid_L2B_Mie_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2B_Mie_Wind_Counts/Invalid_L2B_Mie_Wind_Count')
	List_of_Invalid_L2B_Rayleigh_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2B_Rayleigh_Wind_Counts')
	Invalid_L2B_Rayleigh_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2B_Rayleigh_Wind_Counts/Invalid_L2B_Rayleigh_Wind_Count')
	
	
	#		 L2C Products Only: [N.B. These will need adding to the return statement if used]
	# ~ List_of_Valid_L2C_Mie_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2C_Mie_Wind_Counts')
	# ~ Valid_L2C_Mie_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2C_Mie_Wind_Counts/Valid_L2C_Mie_Wind_Count')
	# ~ List_of_Valid_L2C_Rayleigh_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2C_Rayleigh_Wind_Counts')
	# ~ Valid_L2C_Rayleigh_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Valid_L2C_Rayleigh_Wind_Counts/Valid_L2C_Rayleigh_Wind_Count')
	# ~ List_of_Invalid_L2C_Mie_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2C_Mie_Wind_Counts')
	# ~ Invalid_L2C_Mie_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2C_Mie_Wind_Counts/Invalid_L2C_Mie_Wind_Count')
	# ~ List_of_Invalid_L2C_Rayleigh_Wind_Counts = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2C_Rayleigh_Wind_Counts')
	# ~ Invalid_L2C_Rayleigh_Wind_Count = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Invalid_L2C_Rayleigh_Wind_Counts/Invalid_L2C_Rayleigh_Wind_Count')
	
	#		 Dsds N.B. [For DSD Number add 1 to the python indexes used]
	List_of_Dsds = coda.get_field_names(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds')
	Dsd = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd')
	Meas_Map_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 0)
	Mie_Grouping_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 1)
	Rayleigh_Grouping_Map = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 2)
	Mie_Geolocation_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 3)
	Rayleigh_Geolocation_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 4)
	AMD_Product_Confid_Data_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 5)
	Meas_Product_Confid_Data_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 6)
	Mie_Wind_Product_Conf_Data_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 7)
	Rayl_Wind_Prod_Conf_Data_ADS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 8)
	Mie_Wind_MDS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 9)
	Rayleigh_Wind_MDS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 10)
	Mie_Profile_MDS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 11)
	Rayleigh_Profile_MDS = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 12)
	Aeolus_Level_1B_Product = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 13)
	Aux_Met_Product = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 14)
	Aeolus_RBC = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 15)
	Clim_Product = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 16)
	Cal_Product = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 17)
	Level_2B_Proc_Params = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 18)
	
	#		 L2C Products Only: [N.B. These will need adding to the return statement if used]
	# ~ Aeolus_Level_2B_Product = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 19)
	# ~ Level_2C_Proc_Params = coda.fetch(pfhdr, 'Earth_Explorer_Header/Variable_Header/Specific_Product_Header/List_of_Dsds/Dsd', 20)
	
	return Earth_Explorer_Header, Fixed_Header, File_Name, \
	File_Description, Notes, Mission, File_Class, File_Type, \
	File_Version, Validity_Period, Validity_Start, Validity_Stop, \
	Source, System, Creator, Creator_Version, Creation_Date, \
	Variable_Header, Main_Product_Header, Product, Proc_Stage, \
	Ref_Doc, Acquisition_Station, Proc_Center, Proc_Time, \
	Software_Ver, Baseline, Sensing_Start, Sensing_Stop, Phase, \
	Cycle, Rel_Orbit, Abs_Orbit, State_Vector_Time, Delta_UT1, \
	X_Position, Y_Position, Z_Position, X_Velocity, Y_Velocity, \
	Z_Velocity, Vector_Source, Utc_Sbt_Time, Sat_Binary_Time, \
	Clock_Step, Leap_Utc, Gps_Utc_Time_Difference, Leap_Sign, \
	Leap_Err, Product_Err, Tot_Size, Sph_Size, Num_Dsd, Dsd_Size, \
	Num_Data_Sets, Specific_Product_Header, Sph_Descriptor, \
	NumMeasurements, NumMieGroups, NumRayleighGroups, \
	NumMieWindResults, NumRayleighWindResults, NumMieProfiles, \
	NumRayleighProfiles, NumAMDprofiles, Intersect_Start_Lat, \
	Intersect_Start_Long, Intersect_Stop_Lat, Intersect_Stop_Long, \
	Sat_Track, List_of_Valid_Mie_Profile_Counts, \
	Valid_Mie_Profile_Count, List_of_Valid_Rayleigh_Profile_Counts, \
	Valid_Rayleigh_Profile_Count, List_of_Invalid_Mie_Profile_Counts, \
	Invalid_Mie_Profile_Count, List_of_Invalid_Rayleigh_Profile_Counts, \
	Invalid_Rayleigh_Profile_Count, Num_Profiles_Surface_Mie, \
	Num_Profiles_Surface_Ray, List_of_Valid_L2B_Mie_Wind_Counts, \
	Valid_L2B_Mie_Wind_Count, List_of_Valid_L2B_Rayleigh_Wind_Counts, \
	Valid_L2B_Rayleigh_Wind_Count, List_of_Invalid_L2B_Mie_Wind_Counts, \
	Invalid_L2B_Mie_Wind_Count, List_of_Invalid_L2B_Rayleigh_Wind_Counts, \
	Invalid_L2B_Rayleigh_Wind_Count, List_of_Dsds, Dsd, Meas_Map_ADS, \
	Mie_Grouping_ADS, Rayleigh_Grouping_Map, Mie_Geolocation_ADS, \
	Rayleigh_Geolocation_ADS, AMD_Product_Confid_Data_ADS, \
	Meas_Product_Confid_Data_ADS, Mie_Wind_Product_Conf_Data_ADS, \
	Rayl_Wind_Prod_Conf_Data_ADS, Mie_Wind_MDS, Rayleigh_Wind_MDS, \
	Mie_Profile_MDS, Rayleigh_Profile_MDS, Aeolus_Level_1B_Product, \
	Aux_Met_Product, Aeolus_RBC, Clim_Product, Cal_Product, \
	Level_2B_Proc_Params
	
def load_dbl_tags(dbl):
	# Open DBL file
	pf = coda.open(dbl)
	
	# Get field names and fetch data according to the document:
	# L-2B/2C_I/O_Data_Definitions
	
	# Main_Product_Header
	Product = coda.fetch(pf, 'mph/Product')
	Proc_Stage = coda.fetch(pf, 'mph/Proc_Stage')
	Ref_Doc = coda.fetch(pf, 'mph/Ref_Doc')
	Acquisition_Station = coda.fetch(pf, 'mph/Acquisition_Station')
	Proc_Center = coda.fetch(pf, 'mph/Proc_Center')
	Proc_Time = coda.fetch(pf, 'mph/Proc_Time')
	Software_Ver = coda.fetch(pf, 'mph/Software_Ver')
	Baseline = coda.fetch(pf, 'mph/Baseline')
	Sensing_Start = coda.fetch(pf, 'mph/Sensing_Start')
	Sensing_Stop = coda.fetch(pf, 'mph/Sensing_Stop')
	Phase = coda.fetch(pf, 'mph/Phase')
	Cycle = coda.fetch(pf, 'mph/Cycle')
	Rel_Orbit = coda.fetch(pf, 'mph/Rel_Orbit')
	Abs_Orbit = coda.fetch(pf, 'mph/Abs_Orbit')
	State_Vector_Time = coda.fetch(pf, 'mph/State_Vector_Time')
	Delta_UT1 = coda.fetch(pf, 'mph/Delta_UT1')
	X_Position = coda.fetch(pf, 'mph/X_Position')
	Y_Position = coda.fetch(pf, 'mph/Y_Position')
	Z_Position = coda.fetch(pf, 'mph/Z_Position')
	X_Velocity = coda.fetch(pf, 'mph/X_Velocity')
	Y_Velocity = coda.fetch(pf, 'mph/Y_Velocity')
	Z_Velocity = coda.fetch(pf, 'mph/Z_Velocity')
	Vector_Source = coda.fetch(pf, 'mph/Vector_Source')
	Utc_Sbt_Time = coda.fetch(pf, 'mph/Utc_Sbt_Time')
	Sat_Binary_Time = coda.fetch(pf, 'mph/Sat_Binary_Time')
	Clock_Step = coda.fetch(pf, 'mph/Clock_Step')
	Leap_Utc = coda.fetch(pf, 'mph/Leap_Utc')
	Gps_Utc_Time_Difference = coda.fetch(pf, 'mph/Gps_Utc_Time_Difference')
	Leap_Sign = coda.fetch(pf, 'mph/Leap_Sign')
	Leap_Err = coda.fetch(pf, 'mph/Leap_Err')
	Product_Err = coda.fetch(pf, 'mph/Product_Err')
	Tot_Size = coda.fetch(pf, 'mph/Tot_Size')
	Sph_Size = coda.fetch(pf, 'mph/Sph_Size')
	Num_Dsd = coda.fetch(pf, 'mph/Num_Dsd')
	Dsd_Size = coda.fetch(pf, 'mph/Dsd_Size')
	Num_Data_Sets = coda.fetch(pf, 'mph/Num_Data_Sets')
	
	# Specific_Product_Header
	Sph_Descriptor = coda.fetch(pf, 'sph/Sph_Descriptor')
	NumMeasurements = coda.fetch(pf, 'sph/NumMeasurements')
	NumMieGroups = coda.fetch(pf, 'sph/NumMieGroups')
	NumRayleighGroups = coda.fetch(pf, 'sph/NumRayleighGroups')
	NumMieWindResults = coda.fetch(pf, 'sph/NumMieWindResults')
	NumRayleighWindResults = coda.fetch(pf, 'sph/NumRayleighWindResults')
	NumMieProfiles = coda.fetch(pf, 'sph/NumMieProfiles')
	NumRayleighProfiles = coda.fetch(pf, 'sph/NumRayleighProfiles')
	NumAMDprofiles = coda.fetch(pf, 'sph/NumAMDprofiles')
	Intersect_Start_Lat = coda.fetch(pf, 'sph/Intersect_Start_Lat')
	Intersect_Start_Long = coda.fetch(pf, 'sph/Intersect_Start_Long')
	Intersect_Stop_Lat = coda.fetch(pf, 'sph/Intersect_Stop_Lat')
	Intersect_Stop_Long = coda.fetch(pf, 'sph/Intersect_Stop_Long')
	Sat_Track = coda.fetch(pf, 'sph/Sat_Track')
	
	#	 Counts
	Valid_Mie_Profile_Count = coda.fetch(pf, 'sph/Valid_Mie_Profile_Count')
	Valid_Rayleigh_Profile_Count = coda.fetch(pf, 'sph/Valid_Rayleigh_Profile_Count')
	Invalid_Mie_Profile_Count = coda.fetch(pf, 'sph/Invalid_Mie_Profile_Count')
	Invalid_Rayleigh_Profile_Count = coda.fetch(pf, 'sph/Invalid_Rayleigh_Profile_Count')
	Num_Profiles_Surface_Mie = coda.fetch(pf, 'sph/Num_Profiles_Surface_Mie')
	Num_Profiles_Surface_Ray = coda.fetch(pf, 'sph/Num_Profiles_Surface_Ray')
	Valid_L2B_Mie_Wind_Count = coda.fetch(pf, 'sph/Valid_L2B_Mie_Wind_Count')
	Valid_L2B_Rayleigh_Wind_Count = coda.fetch(pf, 'sph/Valid_L2B_Rayleigh_Wind_Count')
	Invalid_L2B_Mie_Wind_Count = coda.fetch(pf, 'sph/Invalid_L2B_Mie_Wind_Count')
	Invalid_L2B_Rayleigh_Wind_Count = coda.fetch(pf, 'sph/Invalid_L2B_Rayleigh_Wind_Count')
	
	# Dsds
	Dsd = coda.fetch(pf, 'dsd')
	# print((coda.fetch(pf, 'dsd'), 0)[0][0]) ~ Use this format to retrieve coda records
	
	# Measurement_Maps [These relate the L1B measurements to the L2B wind retrievals]
	Meas_Map = coda.fetch(pf, 'meas_map')
	# ~ Meas_Map_ADS_measurement = coda.fetch(pf, 'meas_map', m)
	Mie_Map_of_L1B_Meas_Used = coda.fetch(pf, 'meas_map', -1, 'mie_map_of_l1b_meas_used')
	"""Access via Mie_Map_of_L1B_Meas_Used[m][n], or:"""
	# ~ Mie_Map_of_L1B_Meas_Used_measurement = coda.fetch(pf, 'meas_map', -1, 'mie_map_of_l1b_meas_used', n)
	Rayleigh_Map_of_L1B_Meas_Used = coda.fetch(pf, 'meas_map', -1, 'rayleigh_map_of_l1b_meas_used')
	"""Access via Rayleigh_Map_of_L1B_Meas_Used[m][n], or:"""
	# ~ Rayleigh_Map_of_L1B_Meas_Used = coda.fetch(pf, 'meas_map', -1, 'rayleigh_map_of_l1b_meas_used', n)
	
	#	 Subrecords:
	# Bin = coda.fetch(pf, 'meas_map', -1, 'mie_map_of_l1b_meas_used', n)[m]
	# Which_L2B_Wind_id = coda.fetch(pf, 'meas_map', -1, 'mie_map_of_l1b_meas_used', n)[m][0]
	# Weight = coda.fetch(pf, 'meas_map', -1, 'mie_map_of_l1b_meas_used', n)[m][1]
	"""[Here n is in range(24) and m is in len(Mie_Map_of_L1B_Meas_Used) = NumMeasurements]"""
	
	# Mie and Rayleigh Grouping
	Mie_Grouping = coda.fetch(pf, 'mie_grouping')
	"""Access via Mie_Grouping[l][PI]"""
	Rayleigh_Grouping = coda.fetch(pf, 'rayleigh_grouping')
	"""Access via Rayleigh_Grouping[l][PI]"""
	"""[Here, l is the length of the grouping array and PI is the python index corresponding
	to the tags in Table 19 in the ICD]"""
	
	# Mie and Rayleigh Geolocation
	Mie_Geolocation = coda.fetch(pf, 'mie_geolocation')
	Rayleigh_Geolocation = coda.fetch(pf, 'rayleigh_geolocation')
	
	# Confidence Data
	AMD_Product_Confid_Data = coda.fetch(pf, 'amd_product_confid_data')
	Meas_Product_Confid_Data = coda.fetch(pf, 'meas_product_confid_data')
	Mie_Wind_Prod_Conf_Data = coda.fetch(pf, 'mie_wind_prod_conf_data')
	Rayleigh_Wind_Prod_Conf_Data = coda.fetch(pf, 'rayleigh_wind_prod_conf_data')
	
	# Mie_HLOS_Wind
	Mie_HLOS_Wind = coda.fetch(pf, 'mie_hloswind')
	Rayleigh_HLOS_Wind = coda.fetch(pf, 'rayleigh_hloswind')
	Mie_Profile = coda.fetch(pf, 'mie_profile')
	Rayleigh_Profile = coda.fetch(pf, 'rayleigh_profile')
	
	return Product, Proc_Stage,	Ref_Doc, Acquisition_Station, \
	Proc_Center, Proc_Time, Software_Ver, Baseline, Sensing_Start, \
	Sensing_Stop, Phase, Cycle, Rel_Orbit, Abs_Orbit, State_Vector_Time, \
	Delta_UT1, X_Position, Y_Position, Z_Position, X_Velocity, Y_Velocity, \
	Z_Velocity, Vector_Source, Utc_Sbt_Time, Sat_Binary_Time, \
	Clock_Step, Leap_Utc, Gps_Utc_Time_Difference, Leap_Sign, \
	Leap_Err, Product_Err, Tot_Size, Sph_Size, Num_Dsd, Dsd_Size, \
	Num_Data_Sets, Sph_Descriptor, NumMeasurements, NumMieGroups, \
	NumRayleighGroups, NumMieWindResults, NumRayleighWindResults, \
	NumMieProfiles,	NumRayleighProfiles, NumAMDprofiles, Intersect_Start_Lat, \
	Intersect_Start_Long, Intersect_Stop_Lat, Intersect_Stop_Long, \
	Sat_Track, Valid_Mie_Profile_Count, Valid_Rayleigh_Profile_Count, \
	Invalid_Mie_Profile_Count, Invalid_Rayleigh_Profile_Count, \
	Num_Profiles_Surface_Mie, Num_Profiles_Surface_Ray, \
	Valid_L2B_Mie_Wind_Count, Valid_L2B_Rayleigh_Wind_Count, \
	Invalid_L2B_Mie_Wind_Count, Invalid_L2B_Rayleigh_Wind_Count, \
	Dsd, Meas_Map, Mie_Map_of_L1B_Meas_Used, Rayleigh_Map_of_L1B_Meas_Used, \
	Mie_Grouping, Rayleigh_Grouping, Mie_Geolocation, Rayleigh_Geolocation, \
	AMD_Product_Confid_Data, Meas_Product_Confid_Data, Mie_Wind_Prod_Conf_Data, \
	Rayleigh_Wind_Prod_Conf_Data, Mie_HLOS_Wind, Rayleigh_HLOS_Wind, Mie_Profile, \
	Rayleigh_Profile

def load_rayleigh_data(dbl):
	# Open DBL file
	pf = coda.open(dbl)
	
	# Fetching Data
	rayleigh_wind_velocity = coda.fetch(pf, 'rayleigh_hloswind', -1, 'windresult/rayleigh_wind_velocity')
	rayleigh_latitude = coda.fetch(pf, 'rayleigh_geolocation', -1, 'windresult_geolocation/latitude_cog')
	rayleigh_longitude = coda.fetch(pf, 'rayleigh_geolocation', -1, 'windresult_geolocation/longitude_cog')
	rayleigh_altitude = coda.fetch(pf, 'rayleigh_geolocation', -1, 'windresult_geolocation/altitude_vcog')
	rayleigh_date_time = coda.fetch(pf, 'rayleigh_geolocation', -1, 'windresult_geolocation/datetime_cog')
	rayleigh_azimuth = coda.fetch(pf, 'rayleigh_geolocation', -1, 'windresult_geolocation/los_azimuth')
	rayleigh_satellite_velocity = coda.fetch(pf, 'rayleigh_geolocation', -1, 'windresult_geolocation/los_satellite_velocity')
	mie_wind_velocity = coda.fetch(pf, 'mie_hloswind', -1, 'windresult/mie_wind_velocity')
	mie_latitude = coda.fetch(pf, 'mie_geolocation', -1, 'windresult_geolocation/latitude_cog')
	mie_longitude = coda.fetch(pf, 'mie_geolocation', -1, 'windresult_geolocation/longitude_cog')
	mie_altitude = coda.fetch(pf, 'mie_geolocation', -1, 'windresult_geolocation/altitude_vcog')
	mie_date_time = coda.fetch(pf, 'mie_geolocation', -1, 'windresult_geolocation/datetime_cog')
	mie_azimuth = coda.fetch(pf, 'mie_geolocation', -1, 'windresult_geolocation/los_azimuth')
	mie_satellite_velocity = coda.fetch(pf, 'mie_geolocation', -1, 'windresult_geolocation/los_satellite_velocity')
	
	# Mie and Rayleigh Grouping
	Mie_Grouping = coda.fetch(pf, 'mie_grouping')
	Rayleigh_Grouping = coda.fetch(pf, 'rayleigh_grouping')
	
	# Validity Flags
	Mie_Wind_Prod_Conf_Data = coda.fetch(pf, 'mie_wind_prod_conf_data')
	Rayleigh_Wind_Prod_Conf_Data = coda.fetch(pf, 'rayleigh_wind_prod_conf_data')
	Mie_HLOS_Wind = coda.fetch(pf, 'mie_hloswind')
	Rayleigh_HLOS_Wind = coda.fetch(pf, 'rayleigh_hloswind')
	
	return rayleigh_wind_velocity, rayleigh_latitude, rayleigh_longitude, \
	rayleigh_altitude, rayleigh_date_time, rayleigh_azimuth, \
	rayleigh_satellite_velocity, mie_wind_velocity, mie_latitude, mie_longitude, \
	mie_altitude, mie_date_time, mie_azimuth, mie_satellite_velocity, \
	Mie_Grouping, Rayleigh_Grouping, Mie_Wind_Prod_Conf_Data, \
	Rayleigh_Wind_Prod_Conf_Data, Mie_HLOS_Wind, Rayleigh_HLOS_Wind
	

def createAeolusnc(dbl, outfile):	
	# Load data from DBL file
	data = load_rayleigh_data(dbl)
	rayleigh_time = data[4]
	rayleigh_alt = data[3]
	rayleigh_lat = data[1]
	rayleigh_lon = data[2]
	rayleigh_wind = data[0]
	rayleigh_grouping = data[15]
	Rayleigh_Wind_Prod_Conf_Data = data[17]
	Rayleigh_HLOS_Wind = data[19]
	L2B_Rayleigh_Hlos_Error_Estimate = []
	observation_type = []
	rayleigh_wind_QC = []
	for i in range(len(Rayleigh_Wind_Prod_Conf_Data)):
		L2B_Rayleigh_Hlos_Error_Estimate.append(Rayleigh_Wind_Prod_Conf_Data[i][2][0])
	L2B_Rayleigh_Hlos_Error_Estimate = np.array(L2B_Rayleigh_Hlos_Error_Estimate)
	for j in range(len(Rayleigh_HLOS_Wind)):
		observation_type.append(Rayleigh_HLOS_Wind[j][2][1])
	observation_type = np.array(observation_type)
	for k in range(len(rayleigh_wind)):
		if L2B_Rayleigh_Hlos_Error_Estimate[k] != 1.7e+38 and observation_type[k] == 2:
			rayleigh_wind_QC.append(rayleigh_wind[k])
	rayleigh_wind_QC = np.array(rayleigh_wind_QC)
	
	# Convert list of Rayleigh Group start times into a sensible format
	RG = np.zeros(len(rayleigh_grouping))
	for g in range(len(RG)):
		RG[g] = (rayleigh_grouping[g][1])
	
	# Generate time_units string for .nc file using datetime.datetime array to
	# midnight on the day of the first time element
	time_units = "seconds since " + "2000-01-01" + " 00:00:00"
	
	# Creating netCDF file
	root = nc.Dataset(outfile, 'w', format = "NETCDF4")
	root.contact = "T. P. Banyard, tpb38@bath.ac.uk"
	root.institution = \
	"University of Bath, Claverton Down, Bath, BA2 7AY, United Kingdom"
	root.title = "Aeolus HLOS Rayleigh Wind Data"
	root.Aeolus_data_source = "https://aeolus-ds.eo.esa.int"
	dim_time = root.createDimension("time", len(rayleigh_time))
	dim_RG = root.createDimension("RG", len(RG))
	dim_time_QC = root.createDimension("time_QC", len(rayleigh_wind_QC))
	
	var_time = root.createVariable("time", "f8", ("time",))
	var_time.standard_name = "time"
	var_time.long_name = "time"
	var_time.units = time_units
	
	var_lon = root.createVariable("lon", "f8", ("time",))
	var_lon.standard_name = "longitude"
	var_lon.long_name = "Longitude"
	var_lon.units = "degree_east"
	
	var_lat = root.createVariable("lat", "f8", ("time",))
	var_lat.standard_name = "latitude"
	var_lat.long_name = "Latitude"
	var_lat.units = "degree_north"
	
	var_alt = root.createVariable("alt", "f8", ("time",))
	var_alt.standard_name = "altitude"
	var_alt.long_name = "Altitude"
	var_alt.units = "m"
	
	var_wind = root.createVariable("Rayleigh_HLOS_wind_speed", "f8", ("time",))
	var_wind.standard_name = "wind_speed"
	var_wind.long_name = "Rayleigh_Horizontal_Line_of_Sight_Wind_speed"
	var_wind.units = "cm s-1"
	
	var_wind_QC = root.createVariable("Rayleigh_HLOS_wind_speed_QC", "f8", ("time_QC",))
	var_wind_QC.standard_name = "wind_speed_qc"
	var_wind_QC.long_name = "Rayleigh_Horizontal_Line_of_Sight_Wind_speed_after_quality_control"
	var_wind_QC.notes = "The following quality controls have been applied to this variable: \
	1) Rayleigh Cloudy data removed, leaving only Rayleigh Clear. 2) L2B_Rayleigh_Hlos_Error_Estimate must not equal 1.7e+38"
	var_wind.units = "cm s-1"
	
	var_hlos_error = root.createVariable("L2B_Rayleigh_Hlos_Error_Estimate", "f8", ("time",))
	var_hlos_error.standard_name = "hlos_error"
	var_hlos_error.long_name = "L2B_Rayleigh_Hlos_Error_Estimate"
	var_hlos_error.units = "cm s-1"
	
	var_observation_type = root.createVariable("observation_type", "f8", ("time",))
	var_observation_type.standard_name = "observation_type"
	var_observation_type.long_name = "Observation_Type: 1 = Cloudy, 2 = Clear"
	var_observation_type.units = "unitless"
	
	# N.B. A variable 'var_RG' needs to be created for the plotting.
	# It is of a different dimension though, that of len(RG_time).
	var_RG = root.createVariable("RG", "f8", ("RG",))
	var_RG.standard_name = "rayleigh_grouping"
	var_RG.long_name = "Rayleigh_Grouping"
	var_RG.units = "unitless"
	
	var_time[:], var_lon[:], var_lat[:], var_alt[:], var_wind[:], var_wind_QC[:], \
	var_hlos_error[:], var_observation_type[:], var_RG[:] = rayleigh_time, \
	rayleigh_lon, rayleigh_lat, rayleigh_alt, rayleigh_wind, rayleigh_wind_QC, \
	L2B_Rayleigh_Hlos_Error_Estimate, observation_type, RG
	
	print("Created file of type: ", root.data_model)
	root.close()
	
def createAeolusQCnc(dbl, outfile):	
	# Load data from DBL file
	data = load_rayleigh_data(dbl)
	rayleigh_time = data[4]
	rayleigh_alt = data[3]
	rayleigh_lat = data[1]
	rayleigh_lon = data[2]
	rayleigh_wind = data[0]
	rayleigh_azimuth = data[5]
	rayleigh_satellite_velocity = data[6]
	rayleigh_grouping = data[15]
	Rayleigh_Wind_Prod_Conf_Data = data[17]
	Rayleigh_HLOS_Wind = data[19]
	L2B_Rayleigh_Hlos_Error_Estimate = []
	observation_type = []
	rayleigh_wind_QC = []
	qcflag_both = []
	qcflag_hloserr = []
	qcflag_obstype = []
	
	# Zonal and Meridional projections of HLOS wind
	rayleigh_u_proj = - rayleigh_wind * np.sin(rayleigh_azimuth * (np.pi/180))
	rayleigh_v_proj = - rayleigh_wind * np.cos(rayleigh_azimuth * (np.pi/180))
	
	# L2B_Rayleigh_Hlos_Error_Estimate and observation_type
	for i in range(len(Rayleigh_Wind_Prod_Conf_Data)):
		L2B_Rayleigh_Hlos_Error_Estimate.append(Rayleigh_Wind_Prod_Conf_Data[i][2][0])
	L2B_Rayleigh_Hlos_Error_Estimate = np.array(L2B_Rayleigh_Hlos_Error_Estimate)
	
	for j in range(len(Rayleigh_HLOS_Wind)):
		observation_type.append(Rayleigh_HLOS_Wind[j][2][1])
	observation_type = np.array(observation_type)
	
	"""
	for k in range(len(rayleigh_wind)):
		if L2B_Rayleigh_Hlos_Error_Estimate[k] != 1.7e+38 and observation_type[k] == 2:
			rayleigh_wind_QC.append(rayleigh_wind[k])
	rayleigh_wind_QC = np.array(rayleigh_wind_QC)
	"""
	
	# QCFlag_Both
	for p in range(len(rayleigh_wind)):
		if L2B_Rayleigh_Hlos_Error_Estimate[p] != 1.7e+38 and observation_type[p] == 2:
			qcflag_both.append(1)
		else:
			qcflag_both.append(0)
	qcflag_both = np.array(qcflag_both)
	
	# QCFlag_ObsType
	for r in range(len(rayleigh_wind)):
		if observation_type[r] == 2:
			qcflag_obstype.append(1)
		else:
			qcflag_obstype.append(0)
	qcflag_obstype = np.array(qcflag_obstype)    
	
	# QCFlag_HLOSErr
	for q in range(len(rayleigh_wind)):
		if L2B_Rayleigh_Hlos_Error_Estimate[q] != 1.7e+38:
			qcflag_hloserr.append(1)
		else:
			qcflag_hloserr.append(0)
	qcflag_hloserr = np.array(qcflag_hloserr)
	
	# Convert list of Rayleigh Group start times into a sensible format
	RG = np.zeros(len(rayleigh_grouping))
	for g in range(len(RG)):
		RG[g] = (rayleigh_grouping[g][1])
	
	# Generate time_units string for .nc file using datetime.datetime array to
	# midnight on the day of the first time element
	time_units = "seconds since " + "2000-01-01" + " 00:00:00"
	
	# Creating netCDF file
	root = nc.Dataset(outfile, 'w', format = "NETCDF4")
	root.title = "Aeolus HLOS Rayleigh Wind Data"
	root.contact = "T. P. Banyard, tpb38@bath.ac.uk"
	root.institution = \
	"University of Bath, Claverton Down, Bath, BA2 7AY, United Kingdom"
	root.Aeolus_data_source = "https://aeolus-ds.eo.esa.int"
	root.Date_of_creation = date.today().strftime("%d %b %Y")
	dim_time = root.createDimension("time", len(rayleigh_time))
	dim_RG = root.createDimension("RG", len(RG))
	
	var_time = root.createVariable("time", "f8", ("time",))
	var_time.standard_name = "time"
	var_time.long_name = "time"
	var_time.units = time_units
	
	var_lon = root.createVariable("lon", "f8", ("time",))
	var_lon.standard_name = "longitude"
	var_lon.long_name = "Longitude"
	var_lon.units = "degree_east"
	
	var_lat = root.createVariable("lat", "f8", ("time",))
	var_lat.standard_name = "latitude"
	var_lat.long_name = "Latitude"
	var_lat.units = "degree_north"
	
	var_alt = root.createVariable("alt", "f8", ("time",))
	var_alt.standard_name = "altitude"
	var_alt.long_name = "Altitude"
	var_alt.units = "m"
	
	var_wind = root.createVariable("Rayleigh_HLOS_wind_speed", "f8", ("time",))
	var_wind.standard_name = "wind_speed"
	var_wind.long_name = "Rayleigh_Horizontal_Line_of_Sight_Wind_speed"
	var_wind.units = "cm s-1"
	
	var_azimuth = root.createVariable("LOS_azimuth", "f8", ("time",))
	var_azimuth.standard_name = "los_azimuth"
	var_azimuth.long_name = "Line of sight azimuth angle of the target-to-satellite pointing vector"
	var_azimuth.notes = "Measured in degrees from north"
	var_azimuth.units = "deg"
	
	var_u_proj = root.createVariable("Zonal_wind_projection", "f8", ("time",))
	var_u_proj.standard_name = "zonal_wind_projection"
	var_u_proj.long_name = "Zonal projection of the HLOS wind"
	var_u_proj.units = "cm s-1"
	
	var_v_proj = root.createVariable("Meridional_wind_projection", "f8", ("time",))
	var_v_proj.standard_name = "meridional_wind_projection"
	var_v_proj.long_name = "Meridional projection of the HLOS wind"
	var_v_proj.units = "cm s-1"
	
	var_sat_vel = root.createVariable("Satellite_Velocity", "f8", ("time",))
	var_sat_vel.standard_name = "satellite_velocity"
	var_sat_vel.long_name = "Line of sight velocity of the satellite"
	var_sat_vel.units = "m s-1"
	
	var_QCflag_both = root.createVariable("QC_Flag_Both", "f8", ("time",))
	var_QCflag_both.standard_name = "qc_flag_both"
	var_QCflag_both.long_name = "Binary flag corresponding to both QC filters"
	var_QCflag_both.notes = "The following quality controls have been applied to this variable: \
	1) Rayleigh Cloudy data removed, leaving only Rayleigh Clear. 2) L2B_Rayleigh_Hlos_Error_Estimate must not equal 1.7e+38."
	var_QCflag_both.key = "1 = GOOD, 0 = BAD"
	var_QCflag_both.units = "unitless"
	
	var_QCflag_obstype = root.createVariable("QC_Flag_ObsType", "f8", ("time",))
	var_QCflag_obstype.standard_name = "qc_flag_obstype"
	var_QCflag_obstype.long_name = "Binary flag corresponding to only the observation type QC filter"
	var_QCflag_obstype.notes = "The following quality controls have been applied to this variable: \
	1) Rayleigh Cloudy data removed, leaving only Rayleigh Clear."
	var_QCflag_obstype.key = "1 = GOOD (Clear Sky), 0 = BAD (Cloudy)"
	var_QCflag_obstype.units = "unitless"
	
	var_QCflag_hloserr = root.createVariable("QC_Flag_HLOSErr", "f8", ("time",))
	var_QCflag_hloserr.standard_name = "qc_flag_hloserr"
	var_QCflag_hloserr.long_name = "Binary flag corresponding to only the L2B Rayleigh HLOS Error QC filter"
	var_QCflag_hloserr.notes = "The following quality controls have been applied to this variable: \
	1) L2B_Rayleigh_Hlos_Error_Estimate must not equal 1.7e+38."
	var_QCflag_hloserr.key = "1 = GOOD, 0 = BAD"
	var_QCflag_hloserr.units = "unitless"
	
	# N.B. A variable 'var_RG' needs to be created for the plotting.
	# It is of a different dimension though, that of len(RG_time).
	var_RG = root.createVariable("RG", "f8", ("RG",))
	var_RG.standard_name = "rayleigh_grouping"
	var_RG.long_name = "Rayleigh_Grouping"
	var_RG.units = "unitless"
	
	var_time[:], var_lon[:], var_lat[:], var_alt[:], var_wind[:], var_azimuth[:], \
	var_u_proj[:], var_v_proj[:],	var_sat_vel[:], var_QCflag_both[:],	var_QCflag_obstype[:],  \
	var_QCflag_hloserr[:], var_RG[:] = rayleigh_time, rayleigh_lon, rayleigh_lat, \
	rayleigh_alt, rayleigh_wind, rayleigh_azimuth, rayleigh_u_proj, rayleigh_v_proj, \
	rayleigh_satellite_velocity, qcflag_both, qcflag_obstype, qcflag_hloserr, RG
	
	print("Created file of type: ", root.data_model)
	root.close()

def griddatainterpolation(points, values, alts):
	# ~ print("points: ", points)
	# ~ print("values: ", values)
	# ~ print("alts :", alts)
	if len(points) != len(values) or len(points) < 2:
		result = np.zeros(len(alts))
		return result
		
	# Sort data for spline interpolation
	unsorted_data = sorted(zip(points, values))
	sorted_data = list(zip(*unsorted_data))
	points = np.array(sorted_data[0])
	values = np.array(sorted_data[1])
	
	# Run interpolation
	result = griddata(points, values, alts, method='linear')
	return result
	
def run_interpolation(data_lat_new, data_lon_new, data_alt_new,
	ERA5_data_lat, ERA5_data_lon, ERA5_altitudes, ERA5_curr_data_v, t, t_E):
	"""Runs a 3D interpolation for the ERA5 data onto the IAGOS tracks"""
	
	# Loop this section twice for both the up and down elements in time
	
	# Find aircraft lat/lon (Toggle)
	# ~ print('\nAircraft lat: ', IAGOS_data_lat[t], \
	# ~ '\nAircraft lon: ', IAGOS_data_lon[t])

	# Fixing longitudes for Aeolus data
	for lonidx in range(len(data_lon_new)):
		if data_lon_new[lonidx] >= 180:
			data_lon_new[lonidx] -= 360

	# Find lat/lon box that aircraft is inside (1.5deg boxes to match ERA5)
	# N.B. Ceil & Floor work differently for positive and negative numbers;
	# this should not affect the outcome simply interpolating upside down..?
	# Latitudes
	lat1_val, lat2_val = \
	np.floor(data_lat_new[t]*2/3)*3/2, np.ceil(data_lat_new[t]*2/3)*3/2
	# Avoid the situation where lat1_val = lat2_val for interpolation
	if lat1_val == lat2_val:
		if lat1_val > 0:
			lat1_val -= 3/2
		elif lat1_val <= 0:
			lat1_val += 3/2
	# Longitudes
	lon1_val, lon2_val = \
	np.floor(data_lon_new[t]*2/3)*3/2, np.ceil(data_lon_new[t]*2/3)*3/2
	# Avoid the situation where lon1_val = lon2_val for interpolation
	if lon1_val == lon2_val:
		if lon1_val > 0:
			lon1_val -= 3/2
		elif lon1_val <= 0:
			lon1_val += 3/2
	# Deal with 180deg longitude in ERA5
	if lon1_val == 180.0:
		lon1_val = -180.0
	if lon2_val == 180.0:
		lon2_val = -180.0
	# Print interpolation box (Toggle)
	# ~ print("\nInterpolation box: \nLat: ", lat1_val, " to ", lat2_val)
	# ~ print("Lon: ", lon1_val, " to ", lon2_val)

	# Find corner elements for interpolation on ERA5 grid
	lat1 = np.where(ERA5_data_lat == lat1_val)[0][0]
	lat2 = np.where(ERA5_data_lat == lat2_val)[0][0]
	lon1 = np.where(ERA5_data_lon == lon1_val)[0][0]
	lon2 = np.where(ERA5_data_lon == lon2_val)[0][0]

	# Find the two levels the point is between
	if type(data_alt_new[t]) == np.ma.core.MaskedConstant:
		return None
	nearest_alt = find_nearest(ERA5_altitudes, data_alt_new[t])
	if nearest_alt < data_alt_new[t]:
		# Stop program if plane is above highest altitude level (too high)
		if nearest_alt == ERA5_altitudes[0]:
			return None
		next_nearest_alt = \
		ERA5_altitudes[np.where(ERA5_altitudes == nearest_alt)[0][0]-1]
		# ~ print(next_nearest_alt)
		lev1 = np.where(ERA5_altitudes == nearest_alt)[0][0]
		lev1_val = nearest_alt
		lev2 = np.where(ERA5_altitudes == next_nearest_alt)[0][0]
		lev2_val = next_nearest_alt
	if nearest_alt > data_alt_new[t]:
		# Stop program if plane is below lowest altitude level (too low)
		if nearest_alt == ERA5_altitudes[136]:
			return None
		next_nearest_alt = \
		ERA5_altitudes[np.where(ERA5_altitudes == nearest_alt)[0][0]+1]
		lev1 = np.where(ERA5_altitudes == next_nearest_alt)[0][0]
		lev1_val = next_nearest_alt
		lev2 = np.where(ERA5_altitudes == nearest_alt)[0][0]
		lev2_val = nearest_alt

	# Setting corners of 3D box containing aircraft
	lc1 = ERA5_curr_data_v[t_E][lev1][lat1][lon1] ###################
	lc2 = ERA5_curr_data_v[t_E][lev1][lat1][lon2] #lat2lon1|lat2lon2#
	lc3 = ERA5_curr_data_v[t_E][lev1][lat2][lon1] #(c3)    N    (c4)#
	lc4 = ERA5_curr_data_v[t_E][lev1][lat2][lon2] #     W -+- E     #
	uc1 = ERA5_curr_data_v[t_E][lev2][lat1][lon1] #(c1)    S    (c2)#
	uc2 = ERA5_curr_data_v[t_E][lev2][lat1][lon2] #lat1lon1|lat1lon2#
	uc3 = ERA5_curr_data_v[t_E][lev2][lat2][lon1] ###################
	uc4 = ERA5_curr_data_v[t_E][lev2][lat2][lon2] # lev1 below lev2 #

	# Interpolation in 3D: (lev, lat, lon)
	x = [(lev1_val,lat1_val,lon1_val), (lev1_val,lat1_val,lon2_val), \
	(lev1_val,lat2_val,lon1_val), (lev1_val,lat2_val,lon2_val), \
	(lev2_val,lat1_val,lon1_val), (lev2_val,lat1_val,lon2_val), \
	(lev2_val,lat2_val,lon1_val), (lev2_val,lat2_val,lon2_val)]
	y = [lc1,lc2,lc3,lc4,uc1,uc2,uc3,uc4]
	evaluate_at = \
	[(data_alt_new[t], data_lat_new[t], data_lon_new[t])]
	result = griddata(x, y, evaluate_at)
	return result
	
def topography_interpolation(lon, lat, topo_lon, topo_lat, topo_alt):
	res = 0.25 # Topography dataset resolution

	# Find surrounding latitude bands in topography dataset
	lat_low, lat_hi= \
	np.floor(lat*1/res)*res+(res/2)*(lat/np.abs(lat)), \
	np.ceil(lat*1/res)*res+(res/2)*(lat/np.abs(lat))
	if lat_low < lat < lat_hi:
		pass
	else:
		lat_low, lat_hi= \
		np.floor(lat*1/res)*res+(res/2)*(-lat/np.abs(lat)), \
		np.ceil(lat*1/res)*res+(res/2)*(-lat/np.abs(lat))
	
	# Avoid the situation where lat_low = lat_hi for interpolation
	if lat_low == lat_hi:
		if lat_low > 0:
			lat_low -= res
		elif lat_low <= 0:
			lat_low += res
	
	# Fixing longitude for Aeolus data
	if lon == -180.0:
		lon = 180.0
	if lon <= 0.0:
		lon += 360.0
	
	# Find surrounding longitude bands in topography dataset
	lon_low, lon_hi = \
	np.floor(lon*1/res)*res+(res/2)*(lon/np.abs(lon)), \
	np.ceil(lon*1/res)*(res)+(res/2)*(lon/np.abs(lon))
	if lon_low < lon < lon_hi:
		pass
	else:
		lon_low, lon_hi = \
		np.floor(lon*1/res)*res+(res/2)*(-lon/np.abs(lon)), \
		np.ceil(lon*1/res)*(res)+(res/2)*(-lon/np.abs(lon))
	
	# Avoid the situation where lon_low = lon_hi for interpolation
	if lon_low == lon_hi:
		if lon_low > 0:
			lon_low -= res
		elif lon_low <= 0:
			lon_low += res
	
	# Fixing dateline
	if lon_low == -res/2:
		lon_low += res
	if lon_hi == 360 + res/2:
		lon_hi -= res
	
	# Topography values at each corner
	alt1 = topo_alt[np.where(topo_lat == lat_low)[0][0]][np.where(topo_lon == lon_low)[0][0]]
	alt2 = topo_alt[np.where(topo_lat == lat_hi)[0][0]][np.where(topo_lon == lon_low)[0][0]]
	alt3 = topo_alt[np.where(topo_lat == lat_low)[0][0]][np.where(topo_lon == lon_hi)[0][0]]
	alt4 = topo_alt[np.where(topo_lat == lat_hi)[0][0]][np.where(topo_lon == lon_hi)[0][0]]
	
	# Gathering arrays and finding interpolant
	x = [(lon_low, lat_low), (lon_low, lat_hi), (lon_hi, lat_low), (lon_hi, lat_hi)]
	y = [alt1, alt2, alt3, alt4]
	evaluate_at = [lon, lat]
	result = griddata(x, y, evaluate_at)
		
	return result
	
def era5_grid_interpolation(data_alt_new, ERA5_altitudes, ERA5_curr_data_v):
	"""Runs a 1D interpolation for the ERA5 data onto the a 500m grid"""
	
	# Find the two levels the point is between
	if type(data_alt_new[t]) == np.ma.core.MaskedConstant:
		return None
	nearest_alt = find_nearest(ERA5_altitudes, data_alt_new[t])
	if nearest_alt < data_alt_new[t]:
		# Stop program if plane is above highest altitude level (too high)
		if nearest_alt == ERA5_altitudes[0]:
			return None
		next_nearest_alt = \
		ERA5_altitudes[np.where(ERA5_altitudes == nearest_alt)[0][0]-1]
		# ~ print(next_nearest_alt)
		lev1 = np.where(ERA5_altitudes == nearest_alt)[0][0]
		lev1_val = nearest_alt
		lev2 = np.where(ERA5_altitudes == next_nearest_alt)[0][0]
		lev2_val = next_nearest_alt
	if nearest_alt > data_alt_new[t]:
		# Stop program if plane is below lowest altitude level (too low)
		if nearest_alt == ERA5_altitudes[136]:
			return None
		next_nearest_alt = \
		ERA5_altitudes[np.where(ERA5_altitudes == nearest_alt)[0][0]+1]
		lev1 = np.where(ERA5_altitudes == next_nearest_alt)[0][0]
		lev1_val = next_nearest_alt
		lev2 = np.where(ERA5_altitudes == nearest_alt)[0][0]
		lev2_val = nearest_alt

	# Setting corners of 3D box containing aircraft
	lc1 = ERA5_curr_data_v[t_E][lev1][lat1][lon1] ###################
	lc2 = ERA5_curr_data_v[t_E][lev1][lat1][lon2] #lat2lon1|lat2lon2#
	lc3 = ERA5_curr_data_v[t_E][lev1][lat2][lon1] #(c3)    N    (c4)#
	lc4 = ERA5_curr_data_v[t_E][lev1][lat2][lon2] #     W -+- E     #
	uc1 = ERA5_curr_data_v[t_E][lev2][lat1][lon1] #(c1)    S    (c2)#
	uc2 = ERA5_curr_data_v[t_E][lev2][lat1][lon2] #lat1lon1|lat1lon2#
	uc3 = ERA5_curr_data_v[t_E][lev2][lat2][lon1] ###################
	uc4 = ERA5_curr_data_v[t_E][lev2][lat2][lon2] # lev1 below lev2 #

	# Interpolation in 3D: (lev, lat, lon)
	x = [(lev1_val,lat1_val,lon1_val), (lev1_val,lat1_val,lon2_val), \
	(lev1_val,lat2_val,lon1_val), (lev1_val,lat2_val,lon2_val), \
	(lev2_val,lat1_val,lon1_val), (lev2_val,lat1_val,lon2_val), \
	(lev2_val,lat2_val,lon1_val), (lev2_val,lat2_val,lon2_val)]
	y = [lc1,lc2,lc3,lc4,uc1,uc2,uc3,uc4]
	evaluate_at = \
	[(data_alt_new[t], data_lat_new[t], data_lon_new[t])]
	result = griddata(x, y, evaluate_at)
	return result


def ncload():
	return
