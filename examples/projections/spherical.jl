using Revise
using LasIO
using FileIO
using Images
using Plots
using StaticArrays
using BenchmarkTools

using LiDARSegmentation

# Load the point cloud from a file
path="data/test_cloud.las"

header, cloud = load(path, mmap=true)

# Define the configuration parameters
config = Dict(
              "num_lasers" => 64,
              "horizontal_fov" => deg2rad(0.35),
              "fov_up" => deg2rad(2.0),
              "fov_down" => deg2rad(-24.8),
            )

# Create an instance of the SphericalConversion struct
sp = SphericalProjection{Float64}(config)


# Set origin and create image
origin = SVector{3, Float64}([0.0, 0.0, 0.0])
spherical_images = create_spherical_image(header, cloud, sp, [:x,:y,:z], origin);

normalized_spherical_images  = scale_min_max(spherical_images);


Gray.(normalized_spherical_images[:,:,1])
