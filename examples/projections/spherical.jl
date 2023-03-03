using Revise
using LasIO
using FileIO
using Images
using Plots
using StaticArrays

using LiDARSegmentation

# Load the point cloud from a file
path="data/Cloud.las"

header, cloud = load(path, mmap=true)

# Define the configuration parameters
config = Dict(
              "num_lasers" => 64,
              "horizontal_fov" => deg2rad(0.35),
              "fov_up" => deg2rad(2.0),
              "fov_down" => deg2rad(-24.0),
            )

# Create an instance of the SphericalConversion struct
sp = SphericalProjection{Float64}(config)


# Set origin and create image
origin = SVector{3, Float64}([0,0,0])
spherical_images = create_spherical_image(header, cloud, sp, origin);


# Scale positions
spherical_images[:,:,1] .*= header.x_scale;
spherical_images[:,:,2] .*= header.y_scale;
spherical_images[:,:,3] .*= header.z_scale;

# Convert to [0,1] scale and create image
im = Gray.(map(scaleminmax(header.x_min, header.x_max), spherical_images[:,:,1]))
im = Gray.(map(scaleminmax(header.y_min, header.y_max), spherical_images[:,:,2]))
im = Gray.(map(scaleminmax(header.z_min, header.z_max), spherical_images[:,:,3]))


# Scale range to [0, 1] and create image
f = takemap(scaleminmax, spherical_images[:,:,end])
im_range = Gray.(map(f,  spherical_images[:,:,end]))
