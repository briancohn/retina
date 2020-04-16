
package_dependencies <- c("data.table",
"ggplot2",
"magrittr",
"fields",
"RColorBrewer",
"grDevices",
"retistruct")

package_dependencies <- package_dependencies[!(package_dependencies %in% installed.packages()[,"Package"])]
if(length(package_dependencies)) install.packages(package_dependencies)


library(data.table)
library(ggplot2)
library(magrittr)
library(fields)
library(RColorBrewer)
library(grDevices)
library(retistruct)

### Set contour_breaks based on requested source
##' @title Set Contour Breaks Based on Requested Source
##' @description This function will make a set of contour topography lines. Code from http://stackoverflow.com/questions/10856882/r-interpolated-polar-contour-plot was highly modified to meet retinal plotting functionality.
##' @param contour_breaks_source See fit_plot_azimuthal
##' @param z See fit_plot_azimuthal
##' @param contour_levels See fit_plot_azimuthal
##' @param Mat See fit_plot_azimuthal
##' @return contour_breaks See fit_plot_azimuthal
define_contour_breaks <- function(contour_breaks_source, z, contour_levels, Mat) {
    if ((length(contour_breaks_source == 1)) & (contour_breaks_source[1] == 1)) {
        contour_breaks = seq(min(z, na.rm = TRUE), max(z, na.rm = TRUE), by = (max(z, 
            na.rm = TRUE) - min(z, na.rm = TRUE))/(contour_levels - 1))
    } else if ((length(contour_breaks_source == 1)) & (contour_breaks_source[1] == 
        2)) {
        contour_breaks = seq(min(Mat, na.rm = TRUE), max(Mat, na.rm = TRUE), by = (max(Mat, 
            na.rm = TRUE) - min(Mat, na.rm = TRUE))/(contour_levels - 1))
    } else if ((length(contour_breaks_source) == 2) & (is.numeric(contour_breaks_source))) {
        print(paste0("Manual contour range set from ", contour_breaks_source[1], 
            " to ", contour_breaks_source[2]))
        contour_breaks = pretty(contour_breaks_source, n = contour_levels)
        contour_breaks = seq(contour_breaks_source[1], contour_breaks_source[2], 
            by = (contour_breaks_source[2] - contour_breaks_source[1])/(contour_levels - 
                1))
    } else {
        stop("Invalid selection for \"contour_breaks_source\"")
    }
    return(contour_breaks)
}

### Add contours to the retina plot
##' @title Print contour lines onto the retina plot
##' @description Makes a set of contours to the retinaplot. Modified code from http://stackoverflow.com/questions/10856882/r-interpolated-polar-contour-plot was highly modified to meet retinal plotting functionality.
##' @param minitics See fit_plot_azimuthal
##' @param Mat See fit_plot_azimuthal
##' @param xy two-column dataframe consisting of $x and $y datapoints
##' @param contour_breaks See fit_plot_azimuthal
##' @importFrom grDevices contourLines gray
add_contours <- function(minitics, Mat, contour_breaks, xy) {
    CL <- contourLines(x = minitics, y = minitics, Mat, levels = contour_breaks)
    A <- lapply(CL, function(xy) {
        graphics::lines(xy$x, xy$y, col = gray(0.2), lwd = 0.5)
    })
}

##' @title Initiate the Square Matrix plot to prepare for polar plotting
##' @description instantiates the square plotting area Modified code from http://stackoverflow.com/questions/10856882/r-interpolated-polar-contour-plot was highly modified to meet retinal plotting functionality.
##' @param zlim See fit_plot_azimuthal
##' @param col See fit_plot_azimuthal
##' @param Mat See fit_plot_azimuthal
##' @param minitics See fit_plot_azimuthal
##' @importFrom graphics image
init_square_mat_plot <- function(Mat, zlim, minitics, col) {
    Mat[which(Mat < zlim[1])] = zlim[1]
    Mat[which(Mat > zlim[2])] = zlim[2]
    image(x = minitics, y = minitics, Mat, useRaster = TRUE, asp = 1, axes = FALSE, 
        xlab = "", ylab = "", zlim = zlim, col = col)
}


##' @title Compute fit error at original data points
##' @description compute the error at a set of desired points
##' @author Brian Cohn
##' @param x the x coordinates of the original points that were smoothed
##' @param y the y coordinates of the original points that were smoothed
##' @param thin_plate_spline_object output object from fields::Tps
##' @return error A data frame of the error at each of the original points
compute_thin_plate_spline_error <- function(x, y, thin_plate_spline_object) {
    return(data.frame(x = x, y = y, se = predictSE(thin_plate_spline_object)))
}

##' @title Extract xy points and falciform
##' @description
##' Extracts xy and falciform coordinates from datapoints collected from retistruct. Falc and Datapoints are stacked upon one another
##' @author Brian Cohn
##' @param datapoints_from_retistruct data structure that comes from the datapoints.csv, which is automatically generated by Retistruct.
##' @param number_of_sampling_sites integer
##' @return L list of pixel xy positions, and falciform coordinates in [1] and [2], respectively
##' @export
extract_xy_and_falciform <- function(datapoints_from_retistruct, number_of_sampling_sites) {
    pixel_xy_positions <- datapoints_from_retistruct[1:number_of_sampling_sites, 
        ]
    falciform_len <- length(datapoints_from_retistruct[, 1]) - length(pixel_xy_positions[, 
        1])
    xy_len <- length(pixel_xy_positions[, 1])
    total_len <- length(datapoints_from_retistruct[, 1])
    falciform_coordinates <- datapoints_from_retistruct[(xy_len + 1):total_len, ]
    return(list(pixel_xy_positions, falciform_coordinates))
}

##' @title Reflect IJ Y values for the falciform process
##' @description
##' ImageJ values don't always show up the right way, because Y values get larger and positive while moving down the image.
##' @author Brian Cohn
##' @param falciform_xy_coordinates 2 columns of coordinate (X,Y) data in ImageJ pixel format
##' @param xy_img_dimensions 2-cal list i.e. c(400,200)
##' @return falciform_xy_coordinates_transformed
##' @export
reflect_IJ_y_values_for_falciform <- function(falciform_xy_coordinates, xy_img_dimensions) {
    falciform_xy_coordinates_transformed <- falciform_xy_coordinates  #make a copy
    falc_y <- falciform_xy_coordinates[, 2]
    half_of_vertical_pixels <- xy_img_dimensions[2]/2
    falciform_xy_coordinates_transformed$cyan <- (falc_y - half_of_vertical_pixels) * 
        -1 + half_of_vertical_pixels
    return(falciform_xy_coordinates_transformed)
}


##' @title Traditional Flatmount Plot TODO: implement.
##' @description
##' Shows a visualization of the outline, as well as the location of each datapoint, with fit plot.
##' @author Brian Cohn
##' @param pixel_xy_positions 2 columns of coordinate (X,Y) data in ImageJ pixel format
##' @param z_vector numerical vector of density values for each of the coordinates
##' @param xy_outline_points 2 columns of coordinate(X,Y) data in ImageJ pixel format for the outline coordinates.
##' @return fit the Fit object generated by Tps
##' @export
traditional_flatmount_plot <- function(pixel_xy_positions, z_vector, xy_outline_points, picture_dimensions) {
    fit <- fields::Tps(pixel_xy_positions, z_vector)  # fits a surface to ozone measurements.
    set.panel(2, 2)
    plot(fit)  # four diagnostic plots of  fit and residuals.
    set.panel()
    # summary of fit and estimates of lambda the smoothing parameter
    summary(fit)
    surface(fit)  # Quick image/contour plot of GCV surface.
    return(fit)
}

##' @author Brian Cohn
load_roi <- function(filepath){
    roi_object <- RImageJROI::read.ijroi(file.path(filepath))
    return(roi_object)
}

##' retistruct-style extraction of wholemount outline.
##' @param roi_object result of RImageJROI::read.ijroi
##' @return roi_coordinates XY vals of pixel coordinates of the outline points, in order.
##' @importFrom RImageJROI read.ijroi
##' @export
extract_wholemount_outline <- function(roi_object) {
    return(apply_retistruct_imageJ_inversion(roi_object$coords))
}

# helper fn derived from retistruct source. Accessed Dec 1, 2019
##' @param xy_coords dataframe with 2 columns for x and y
##' @value xy_coord_prime dataframe with 2 columns for x and y, only y col is modified.
apply_retistruct_imageJ_inversion <- function(xy_coords, input_offset = NULL){
    offset <- ifelse(is.null(input_offset),max(xy_coords[, 2]),input_offset)
    xy_coords[, 2] <- offset - xy_coords[, 2]
    return(xy_coords)
}

apply_retistruct_inversion_to_datapoints <- function(xy_coords, roi_obj){
    return(apply_retistruct_imageJ_inversion(xy_coords, input_offset = max_yval(roi_obj)))
}
generate_projection_data <- function(prepped_xy_coord,retistruct_object){
    coordinate <- map_radian_coords(retistruct_object, prepped_xy_coord)
    coordinate_dt <- data.table(cbind(prepped_xy_coord, coordinate, degrees(coordinate)))
    coordinate_dt[,successful_mapping := !is.na(phi)][]
    res <- azimuthal_projection(coordinate_dt)
    return(res[])
}

azimuthal_projection<- function(dtt){
    az <- mapproj::mapproject(x = dtt$lambda_deg, dtt$phi_deg, projection = "azequidistant", 
            orientation = c(-90, 0, 0))

    dtt[,azi_x:=az$x]
    dtt[,azi_y:=az$y]
    return(dtt[])
}

max_yval <- function(outline_roi_object){
    return (max(outline_roi_object$coords[,2]))
}

plot_outline <- function(roi_XY_coords){
    inverted_ylims <- c(
        max(roi_XY_coords[,2]),
        min(roi_XY_coords[,2])
        )
    plot(roi_XY_coords, type = "l", col = "#d3d3d3", asp = 1, xlab = "X Pixels", ylab = "Y Pixels", ylim=inverted_ylims)
    text(roi_XY_coords[, 1], roi_XY_coords[, 2], labels = 1:length(roi_XY_coords[,1]), cex = 0.5)
}

##' TODO document"
get_xyz_points <- function(path_to_retina_data_folder){

    xyz <- read.csv(file.path(path_to_retina_data_folder,"xyz.csv"))
    xy_in_outline_coord_frame <- read.csv(file.path(path_to_retina_data_folder,"datapoints.csv"))
    
    offset <- ifelse(is.null(im), max(xy_in_outline_coord_frame[, 2]), nrow(im))
    xy_in_outline_coord_frame[, 2] <- offset - xy_in_outline_coord_frame[, 2]

    offset <- ifelse(is.null(im), max(xy_in_outline_coord_frame[, 1]), nrow(im))
    xy_in_outline_coord_frame[, 1] <- offset - xy_in_outline_coord_frame[, 1]
    num_ssites <- nrow(xyz)

    xy_in_outline_coord_frame$num_cells <- c(xyz[,3], rep(-1, nrow(xy)-num_ssites))
    xy_in_outline_coord_frame$sampling_site <- 1:nrow(xy_in_outline_coord_frame)
    colnames(xy_in_outline_coord_frame) <- c( "x","y" ,"num_cells",  "sampling_site")
    return(xy_in_outline_coord_frame)
    }



##' @title Assemble markup file
##' @description Creates a markup.csv file. One of the dorsal_outline_index or nasal_outline_index must be filled in. Not both.
##' @author Brian Cohn
##' @param eye_left_or_right either 'left' or 'right'
##' @param dorsal_outline_index The index of the point that points toward dorsal, or NA.
##' @param nasal_outline_index The index of the opint that points toward nasal, or NA.
##' @param path_to_retina_data_folder The path where the markup.csv file will be saved.
##' @export
assemble_markup_file <- function(eye_left_or_right, path_to_retina_data_folder, dorsal_outline_index = NA, 
    nasal_outline_index = NA, phi0 = 0) {
    firstup <- function(x) {
        ## https://stackoverflow.com/questions/18509527/first-letter-to-upper-case
        substr(x, 1, 1) <- toupper(substr(x, 1, 1))
        x
    }
    eye_side_string <- firstup(eye_left_or_right)
    if (is.na(dorsal_outline_index)) {
        line2 <- paste0("NA,", nasal_outline_index, ",",phi0,",NA,TRUE,\"", eye_side_string, 
            "\"")
    } else {
        line2 <- paste0(dorsal_outline_index, ",NA", ",",phi0,",NA,TRUE,\"", eye_side_string, 
            "\"")
    }
    line1 <- "\"iD\",\"iN\",\"phi0\",\"iOD\",\"DVflip\",\"side\""
    output_path <- file.path(path_to_retina_data_folder, "markup.csv")
    file.create(output_path)
    write(line1, file = output_path, append = TRUE)
    write(line2, file = output_path, append = TRUE)
}


##' @title Assemble tear file
##' @description Creates a T.csv file
##' @author Brian Cohn
##' @param tear_coordinates_dataframe the dataframe of 3 columns, with c('V0','VB','VF'), and n columns, where n= number of tears
##' @param path_to_retina_data_folder The path where the T.csv file will be saved.
##' @return tear_coordinates_dataframe Tear coords in retistruct format
##' @export
##' @importFrom utils write.table
assemble_tear_file <- function(tear_coordinates_dataframe, path_to_retina_data_folder) {
    output_path <- file.path(path_to_retina_data_folder, "T.csv")
    colnames(tear_coordinates_dataframe) <- c("V0", "VB", "VF")
    write.table(tear_coordinates_dataframe, output_path, sep = ",", row.names = FALSE)
    return(tear_coordinates_dataframe)
}

##' @title Add scatter X's of XY to an existing plot
##' @description visualize xy points as X's
##' @author Brian Cohn
##' @param x numeric vector of x coordinates
##' @param y numeric vector of y coordinates
##' @importFrom graphics points
plot_original_xy_locations <- function(x, y) {
    points(x + 0.005, y, pch = 4, cex = 0.5, col = "gainsboro")
    points(x, y, pch = 4, cex = 0.5, col = "black")
}

##' @title Plot the degree labels for latitudes
##' @description Plot degree numbers
##' @author Brian Cohn
##' @param outer_radius the extent of the radius of the plot
##' @param circle.rads the number of radian circles that are drawn
##' @importFrom graphics axis text
plot_degree_label_for_latitudes <- function(outer_radius, circle.rads) {
    axis(2, pos = -1.25 * outer_radius, at = sort(union(circle.rads, -circle.rads)), 
        labels = NA)
    text(-1.26 * outer_radius, sort(union(circle.rads, -circle.rads)), sort(union(circle.rads, 
        -circle.rads)), xpd = TRUE, pos = 2, family = "Palatino")
}


##' @title add a basic legend
##' @description plot a basic legend
##' @author Brian Cohn
##' @import fields
##' @param col Color vector
##' @param zlim limits of the densities
##' @importFrom graphics par
add_legend <- function(col, zlim) {
    par(mai = c(1, 1, 1.5, 1.5))
    fields::image.plot(legend.only = TRUE, col = col, zlim = zlim, family = "Palatino")
    par(mar = c(1, 1, 1, 1))
}

##' @title draw line segments
##' @description put the radial lines on the plot
##' @author Brian Cohn
##' @param endpoints a 4 element numeric vector describing the xy and x'y' for the line segment.
##' @param color_hex hex string
##' @importFrom graphics segments
draw_line_segments <- function(endpoints, color_hex = "#66666650") {
    segments(endpoints[1], endpoints[2], endpoints[3], endpoints[4], col = color_hex)
}


##' @title Write labels at endpoint locations
##' @description put labels around the circle at each of the lines
##' @author Brian Cohn
##' @param r_label string of right label
##' @param l_label string of left label
##' @param degree the degree that is being placed in
##' @param endpoints vector of 4 numerics, x,y and x',y' defining the line segment
write_labels_at_endpoint_locations <- function(r_label, l_label, degree, endpoints) {
    lab1 <- bquote(.(r_label) * degree)
    lab2 <- bquote(.(l_label) * degree)
    text(endpoints[1], endpoints[2], lab1, xpd = TRUE, family = "Palatino")
    text(endpoints[3], endpoints[4], lab2, xpd = TRUE, family = "Palatino")
}


##' @title Remove points that are outside of the plotting circle
##' @description We do not need points plotted in the corners of the plotted circle.
##' @author Brian Cohn
##' @param minitics Spherical limit info
##' @param spatial_res spatial width in pixels of the plotted image
##' @param heatmap_matrix Matrix of predicted points on the set grid
##' @param outer_radius max value of the radius
##' @return matrix_to_mask the masking values outside of the circle
nullify_vals_outside_the_circle <- function(minitics, spatial_res, heatmap_matrix, 
    outer_radius) {
    matrix_position_is_within_the_circle <- function() {
        !sqrt(markNA^2 + t(markNA)^2) < outer_radius
    }
    markNA <- matrix(minitics, ncol = spatial_res, nrow = spatial_res)
    matrix_to_mask <- heatmap_matrix  #matrix_to_mask is a mutable variable
    matrix_to_mask[matrix_position_is_within_the_circle()] <- NA  #MUTABLE
    return(matrix_to_mask)
}


##' @title Compute Longitude Label Location
##' @description Find the location to put the label around the circle at each of the lines
##' @author Brian Cohn
##' @param axis.rads axis.rads
##' @param outer_radius numeric value for radius limit
##' @return label_locations the computed location for a label
compute_longitude_label_location <- function(axis.rads, outer_radius) {
    return(c(RMat(axis.rads) %*% matrix(c(1.1, 0, -1.1, 0) * outer_radius, ncol = 2)))
}

##' @title Plot longitudinal spoke lines
##' @description put lines across the plotting circle
##' @author Brian Cohn
##' @param axis_radian radian
##' @param outer_radius numeric value of the outer radius limit
plot_longitudinal_lines <- function(axis_radian, outer_radius) {
    endpoints <- zapsmall(c(RMat(axis_radian) %*% matrix(c(1, 0, -1, 0) * outer_radius, 
        ncol = 2)))
    draw_line_segments(endpoints)
}

##' @title Plot longitudinal labels
##' @description put a degree label at the ends of the endpoints for each longitude
##' @author Brian Cohn
##' @param axis.rad axis radian
##' @param outer_radius numeric value of the outer radius limit
##' @param r_label label number
##' @param l_label label number
##' @param degree numeric, the degree of interest
plot_longitudinal_labels <- function(axis.rad, outer_radius, r_label, l_label, degree) {
    write_labels_at_endpoint_locations(r_label, l_label, degree, compute_longitude_label_location(axis.rad, 
        outer_radius))
}


##' @title Internal equation for axis markup
##' @description define locations for radians with trigonometry
##' @author Brian Cohn
##' @param radians vector of radians
##' @return RMat trigonometric positions
RMat <- function(radians) {
    return(matrix(c(cos(radians), sin(radians), -sin(radians), cos(radians)), ncol = 2))
}

##' @title Draw Latitude Markings
##' @description plots radial lines, degree label for latitudes, and plots radial spokes with labels
##' @author Brian Cohn
##' @param radius_vals vector of radius values (for latitudes)
##' @param outer_radius see fitplotazimuthal
draw_latitude_markings <- function(radius_vals, outer_radius) {
    plot_circle_radial_lines(radius_vals)
    plot_degree_label_for_latitudes(outer_radius, radius_vals)
    plot_radial_spokes_and_labels(outer_radius)
}

##' @title Draw circle radians about the center
##' @description Draw N radius lines (circles)
##' @author Brian Cohn
##' @param radius_vals vector of radius values where the circles will be drawn
##' @param color_hex hex color string, '#666650' is the default
##' @importFrom graphics lines
plot_circle_radial_lines <- function(radius_vals, color_hex = "#666650") {
    circle <- function(x, y, rad = 1, nvert = 500) {
        rads <- seq(0, 2 * pi, length.out = nvert)
        xcoords <- cos(rads) * rad + x
        ycoords <- sin(rads) * rad + y
        cbind(xcoords, ycoords)
    }
    for (i in radius_vals) {
        lines(circle(0, 0, i), col = color_hex)
    }
}

##' @title Define Zlim by the requested color breaks source
##' @description Set color breaks (zlim) based on requested source
##' @author Brian Cohn
##' @param col_breaks_source A 2 element vector with max and min
##' @param z the response values from the input data (the retinal densities)
##' @param Mat The predicted retinal densities across the xy space
define_color_breaks_based_on_source <- function(col_breaks_source, z, Mat) {
    if ((length(col_breaks_source) == 1) & (col_breaks_source[1] == 1)) {
        zlim <- c(min(z, na.rm = TRUE), max(z, na.rm = TRUE))
    } else if ((length(col_breaks_source) == 1) & (col_breaks_source[1] == 2)) {
        zlim <- c(min(Mat, na.rm = TRUE), max(Mat, na.rm = TRUE))
    } else if ((length(col_breaks_source) == 2) & (is.numeric(col_breaks_source))) {
        zlim <- col_breaks_source
    } else {
        stop("Invalid selection for \"col_breaks_source\"")
    }
    return(zlim)
}


##' @title fit & interpolate input data
##' useful for 2-->1 mapping (i.e. xy -> pred(z))
##' @author Brian Cohn
##' @param minitics locations to predict at
##' @param x,y input training data
##' @param z training response data
##' @param lambda param to Tps
##' @param polynomial_m param to Tps
##' @param extrapolate whether to predict out to the equator of the eye, even if no data exists nearby.
interpolate_input_data <- function(minitics, x, y, z, lambda, polynomial_m, extrapolate) {
    grid.list = list(x = minitics, y = minitics)  #choose locations to predict at
    t <- Tps(cbind(x, y), z, lambda = lambda, m = polynomial_m)  #computationally intensive
    tmp <- predictSurface(t, grid.list, extrap = extrapolate)
    Mat <- tmp$z
    return(list(t = t, tmp = tmp, Mat = Mat))
}




##' @title Plot radial axes
##' @description Put radial axes onto visualization
##' @author Brian Cohn
##' @param outer_radius numeric value of the outer radius limit
plot_radial_spokes_and_labels <- function(outer_radius) {
    axis.rads <- c(0, pi/6, pi/3, pi/2, 2 * pi/3, 5 * pi/6)
    r.labs <- c(90, 60, 30, 0, 330, 300)
    l.labs <- c(270, 240, 210, 180, 150, 120)
    for (i in 1:length(axis.rads)) {
        plot_longitudinal_lines(axis.rads[i], outer_radius)
        plot_longitudinal_labels(axis.rads[i], outer_radius, r.labs[i], l.labs[i], 
            i)
    }
}

##' @title Create a pretty number list up to but not including the upper limit
##' @description Remove the last element if it exceeds the upper limit
##' @author Brian Cohn
##' @param upper_limit numeric upper bound
##' @param lower_limit numeric lower bound
##' @return pretty_vec numeric vector
pretty_list_not_including_max <- function(lower_limit, upper_limit) {
    radian_list <- pretty(c(lower_limit, upper_limit))
    if (max(radian_list) > upper_limit) {
        return(radian_list[1:length(radian_list) - 1])
    } else {
        return(radian_list)
    }
}

##' @title Polygon Spline Fit
##' @description Useful for making the falciform process look more smooth and refined. This is purely aesthetic.
##' @details enhance the resolution of a polygon vertices dataframe by creating a spline along each vertex.
##' @param xy vertices in dataframe with x and y columns, in order (not all are used).
##' @param vertices Number of spline vertices to create.
##' @param k Wraps K vertices around each end. n >=k
##' @param ... further arguments passed to or from other methods.
##' @return Coords More finely placed vertices for the polygon.
##' @author Brian Cohn \email{brian.cohn@@usc.edu}, Lars Schmitz
##' @importFrom stats spline
##' @references http://gis.stackexchange.com/questions/24827/how-to-smooth-the-polygons-in-a-contour-map
spline_poly <- function(xy, vertices, k = 3, ...) {
    n <- dim(xy)[1]
    if (k >= 1) {
        data <- rbind(xy[(n - k + 1):n, ], xy, xy[1:k, ])
    } else {
        data <- xy
    }
    # Spline the x and y coordinates.
    data.spline <- spline(1:(n + 2 * k), data[, 1], n = vertices, ...)
    x <- data.spline$x
    x1 <- data.spline$y
    x2 <- spline(1:(n + 2 * k), data[, 2], n = vertices, ...)$y
    
    # Retain only the middle part.
    cbind(x1, x2)[k < x & x <= n + k, ]
}

##' @title Retina Plot
##'
##' @description
##' you can also use extrapolate == TRUE to extend your plot to the boundary of the eye, but this is not advised unless you have lots of points spanning the space. The quality of the fit is not supported outside the range of the training data.
##' \code{retinaplot} Generates an Azimuthal Equidistant plot projection of a retina object.
##' You can also set lambda(floating point number) and polynomial_m(integer), as well as extrapolate (TRUE, FALSE).
##' @param inner_eye_view boolean, default is TRUE. If set to false, the plotted view of the retina will have the viewpoint within the skull looking at the rear of the eye. inner_eye_view has the same view as the traditional wholemount.
##' @param ... further arguments passed to or from other methods.
##' @param rotation degrees to rotate CCW (int or floating point)
##' @param return_fit logical, whether or not to return the interpolation fit data.
##' @param spatial_res define the number of pixels (resolution) the plot will be
##' @param retina_object A list containing an element \code{azimuthal_data.datapoints} with
##' \code{x,y,z} datapoints. File must also include \code{azimuthal_data.falciform}.
##' @return Base-R polar plot
##'
##' @author Brian Cohn \email{brian.cohn@@usc.edu}, Lars Schmitz
##'
##'
##' @family visualization
##' @export
retinaplot <- function(retina_object, spatial_res = 1000, rotation = 0, inner_eye_view = TRUE, 
    return_fit = FALSE, ...) {
    AZx <- retina_object$azimuthal_data.datapoints[[1]]$x
    AZy <- retina_object$azimuthal_data.datapoints[[1]]$y
    AZz <- retina_object$azimuthal_data.datapoints[[1]]$z
    # if (rotation !=0){
    rotAZ <- cartesian_rotation(AZx, AZy, rotation)
    AZx <- rotAZ$x
    AZy <- rotAZ$y
    rotFALC <- cartesian_rotation(retina_object$azimuthal_data.falciform[[1]]$x, 
        retina_object$azimuthal_data.falciform[[1]]$y, rotation)
    retina_object$azimuthal_data.falciform[[1]]$x <- rotFALC$x
    retina_object$azimuthal_data.falciform[[1]]$y <- rotFALC$y
    message(paste("rotated by", rotation, "degrees"))
    # }
    if (inner_eye_view == TRUE) {
        AZx <- AZx * -1
        retina_object$azimuthal_data.falciform[[1]]$x <- retina_object$azimuthal_data.falciform[[1]]$x * 
            -1
    }
    temp <- fit_plot_azimuthal(AZx, AZy, AZz, outer_radius = 1.6, spatial_res = spatial_res, 
        falciform_coords = retina_object$azimuthal_data.falciform[[1]], falc2 = NA, 
        ...)
    if (return_fit) {
        return(temp)
    }
}


##' @title Polar Interpolation
##' @description This function will make a plot. Code from http://stackoverflow.com/questions/10856882/r-interpolated-polar-contour-plot was highly modified to meet retinal plotting functionality.
##' @param x,y,z cartesian input in azimuthal format
##' @param contours whether to plot contours.
##' @param legend Color legend with tick marks
##' @param axes Radial axes
##' @param extrapolate By default FALSE, will make surface within the bounds of observed datapoints within the circle.
##' @param col_breaks_source 2 element vector with max and min
##' @param col_levels number of color levels
##' @param col colors to plot
##' @param contour_breaks_source 1 if data, 2 if calculated surface data
##' @param contour_levels number of contour levels
##' @param outer_radius size of plot
##' @param circle.rads radius lines
##' @param spatial_res Used to define a spatial_res by spatial_res plotting resolution.
##' @param lambda lambda value for thin plate spline interpolation
##' @param xyrelief scaling factor for interpolation matrix.
##' @param tmp_input tmp_input
##' @param plot_suppress by default FALSE
##' @param compute_error whether to use fields::predictSE
##' @param falciform_coords vertices in xy format of the falciform process
##' @param falc2 a second falficorm coordinate file
##' @param should_plot_points boolean, whether to plot the sampling site locations
##' @param single_point_overlay Overlay 'key' data point with square
##' @param polynomial_m A polynomial function of degree (m-1) will be included in the model as the drift (or spatial trend) component. Default is the value such that 2m-d is greater than zero where d is the dimension of x.
##' @param ... passed arguments
##' @import fields rgl RColorBrewer
##' @importFrom grDevices colorRampPalette
##' @export
fit_plot_azimuthal <- function(x, y, z, contours = TRUE, legend = TRUE, axes = TRUE, 
    should_plot_points = TRUE, extrapolate = FALSE, col_breaks_source = 2, col_levels = 50, 
    col = rev(grDevices::colorRampPalette(RColorBrewer::brewer.pal(11, "PuOr"))(col_levels)), contour_breaks_source = 1, 
    contour_levels = col_levels + 1, outer_radius = pi/2, circle.rads = pretty_list_not_including_max(0, 
        outer_radius), spatial_res = 1000, single_point_overlay = 0, lambda = 0.001, 
    xyrelief = 1, tmp_input = NULL, plot_suppress = FALSE, compute_error = FALSE, 
    falciform_coords = NULL, falc2 = NA, polynomial_m = NULL, ...) {
    
    minitics <- seq(-outer_radius, outer_radius, length.out = spatial_res)
    vals <- interpolate_input_data(minitics, x, y, z, lambda, polynomial_m, extrapolate)
    t <- vals$t
    tmp <- vals$tmp
    Mat <- vals$Mat
    if (compute_error) {
        error <- compute_thin_plate_spline_error(x, y, vals$t)
    } else {
        error <- NULL
    }
    heatmap_matrix <- nullify_vals_outside_the_circle(minitics, spatial_res, Mat, 
        outer_radius)
    
    if (plot_suppress == TRUE) {
        return(list(t, tmp, error))
    }
    
    zlim <- define_color_breaks_based_on_source(col_breaks_source, z, heatmap_matrix)
    init_square_mat_plot(heatmap_matrix, zlim, minitics, col)
    if (contours) {
        add_contours(minitics, heatmap_matrix, contour_breaks = define_contour_breaks(contour_breaks_source, 
            z, contour_levels, heatmap_matrix), Mat)
    }
    if (!is.na(falciform_coords)) 
        plot_falciform_process(falciform_coords$x, falciform_coords$y)
    if (should_plot_points) 
        plot_original_xy_locations(x, y)
    if (axes) 
        draw_latitude_markings(circle.rads, outer_radius)
    if (legend) 
        add_legend(col, zlim)
    
    return(list(t, tmp, error,heatmap_matrix=heatmap_matrix))
}

##' @title Plot falciform process
##' @description smooths and plots the falciform process
##' @author Brian Cohn
##' @param falciform_x numeric vector of x coordinates
##' @param falciform_y numeric vector of y coordinates
##' @importFrom graphics polygon
##' @importFrom grDevices rgb
plot_falciform_process <- function(falciform_x, falciform_y) {
    fc_smoothed <- spline_poly(cbind(falciform_x, falciform_y), vertices = 50)
    polygon(fc_smoothed[, 1], fc_smoothed[, 2], col = rgb(0, 0, 0, 0.5), lty = "solid", 
        border = "gray42")
}

##' make a composite plot
##' if there is an NA in a position for any of the maps, it will create a NA in the output. 
##' That way we do not show areas that were not covered by all scans of the retina
##' @param list_of_maps list of retina objects
##' @param map_names_vector name for each of the retina objects. Used for the boxplot
##' @param show_boxplot whether or not to display the values for all retinas
##' @param composite matrix of the mean values. 
##' @author Brian Cohn
multimap_composite <- function(list_of_maps, map_names_vector, show_boxplot=TRUE){
    num_maps <- length(list_of_maps)
    mean_map_mat <- Reduce(function(map1,map2) {map1 + map2}, list_of_maps, 0) / num_maps
    print_span_comparison(list_of_maps, mean_map_mat)

    if (show_boxplot){
        len_with_mean <- length(list_of_maps)+1
        list_of_maps[[len_with_mean]] <- mean_map_mat
        map_names_vector[len_with_mean] <- "Mean map (composite)"
        boxplot(list_of_maps, names = map_names_vector, xlab = "Retinal ganglion cells per square mm",
        horizontal = TRUE, pch = 20, cex = 0.5, col = "darkgrey")
    }
    return(mean_map_mat)
}

##' make a composite plot
##' @param list_of_maps list of retina objects
##' @param map_names_vector name for each of the retina objects. Used for the boxplot
##' @param show_boxplot whether or not to display the values for all retinas
plot_multimap_composite <- function(mean_map_mat, show_boxplot=TRUE){
    matrange <- range(mean_map_mat, na.rm=TRUE)
    spatial_res <- nrow(mean_map_mat)
    plot_from_MAT(density_matrix=mean_map_mat, extrapolate=FALSE, spatial_res=spatial_res, col_levels=50, contour_levels = 20, contour_breaks_source=matrange,col_breaks_source=matrange)
}

##' @title Conversion from Radians to Degrees
##' @description This is a simple internal function used to convert radians to degrees. It does not accommodate for degrees larger than one period.
##' @param radian_coords A data.frame with two columns- first is phi, second is lambda
##' @return data.frame Phi and lambda in a data.frame.
##' @author Brian Cohn \email{brian.cohn@@usc.edu}, Lars Schmitz
degrees <- function(radian_coords) {
    phi_deg <- radian_coords$phi * (180/pi)  #convert to degrees, phi is out latitude
    lambda_deg <- radian_coords$lambda  * (180/pi)  #convert to degrees, lambda is our longitude, use this to rotate about the eye through-axis
    return(data.frame(phi_deg = phi_deg, lambda_deg = lambda_deg))
}
#just extract the roi data you need
get_coords_from_roi <- function(path_to_retina_data_folder) RImageJROI::read.ijroi(file.path(path_to_retina_data_folder, "outline.roi"))$coords

#if there is no spot on the hemisphere, it will return c(NA,NA). else, it will returnthe phi/lambda coordinate.
map_flat_coord <- function(my_row, r){
    coords <- r$mapFlatToSpherical(cbind(X=my_row[[1]],Y=my_row[[2]]))
    if(is.na(coords[1])){
        return(c(NA,NA))
    } else{
        return(c(coords[1],coords[2]))
    }
    }


add_name_col <- function(dt_input, name){
    dt_input[,name := name][]
}

map_radian_coords <- function(retistruct_object, tall_coordinate_df){
    res <- apply(tall_coordinate_df, 1, map_flat_coord, r=retistruct_object)
    spherical_coords <- data.table(t(res))
    colnames(spherical_coords) <- c("phi","lambda")
    return(spherical_coords)
}


closest_row_to_point<- function(input_grid_dt,x_val,y_val){
    dt <- na.omit(input_grid_dt, cols="azi_x")
    dt[,pole_az_distance := sqrt((azi_x-x_val)^2 + (azi_y-y_val)^2)]
    dt[which.min(dt$pole_az_distance)][]
}


# take in a 2 dimensional input df. will create grid based on bounding rectangle.
grid_within_bounding_box <- function(xy_data,points_per_dimension = 100){

# gets the max and min of a vector, and creates equispaced elements across that range
grid_in_1d_box <- function(input_vector, points_per_dimension){
    x <- seq(min(input_vector), max(input_vector),length.out=points_per_dimension)
    return(x)
}
ranges <- apply(xy_data,2,grid_in_1d_box, points_per_dimension = points_per_dimension)
d1 <- expand.grid(x = ranges[,1], y = ranges[,2])
colnames(d1) <- colnames(xy_data)[1:2]
return(d1)

}

save_outline_indices_plot <- function(input_roi_path, input_measurements, input_location){
    pdf(input_location, width=10,height=10)
    outline_indices_plot(input_roi_path, input_measurements)
    dev.off()
}

outline_indices_plot<- function(input_roi, input_measurements){
        plot_outline(input_roi$coords)
        points(input_measurements, pch=15,cex=0.6)
        text(input_measurements, labels = as.character(1:nrow(input_measurements)), cex = 0.2, col="white")
}

directional_landmarks <- function(grid_dt_input){
    rbind(
    closest_row_to_point(grid_dt_input,0,0) %>% add_name_col("+"),
    closest_row_to_point(grid_dt_input,0,pi/2) %>% add_name_col("D"),
    closest_row_to_point(grid_dt_input,0,-pi/2) %>% add_name_col("V"),
    closest_row_to_point(grid_dt_input,pi/2,0) %>% add_name_col("R"),
    closest_row_to_point(grid_dt_input,-pi/2,0) %>% add_name_col("L")
)}
