#include "../src/watermark_engine.hpp"
#include "../assets/embedded_assets.hpp"
#include <iostream>
#include <vector>
#include <cmath>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>

// Simple assertion macro
#define ASSERT(condition, message) \
    do { \
        if (!(condition)) { \
            std::cerr << "FAIL: " << message << " (" << #condition << ") at " << __FILE__ << ":" << __LINE__ << std::endl; \
            return 1; \
        } \
    } while (0)

int main() {
    std::cout << "Running Regression Test..." << std::endl;

    try {
        // Initialize Engine
        gwt::WatermarkEngine engine(
            gwt::embedded::bg_48_png, gwt::embedded::bg_48_png_size,
            gwt::embedded::bg_96_png, gwt::embedded::bg_96_png_size
        );

        // Create a synthetic test image (Gradient)
        // Size 2000x2000 to trigger Large watermark (96x96)
        int width = 2000;
        int height = 2000;
        cv::Mat test_img(height, width, CV_8UC3);

        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                test_img.at<cv::Vec3b>(y, x) = cv::Vec3b(
                    (x * 255) / width,
                    (y * 255) / height,
                    128
                );
            }
        }

        cv::Mat original = test_img.clone();
        cv::Mat processed = test_img.clone();

        // Roundtrip: Add -> Remove
        std::cout << "Adding watermark..." << std::endl;
        engine.add_watermark(processed);
        
        // Sanity check: processed should be different from original
        double diff_norm = cv::norm(original, processed, cv::NORM_L2);
        ASSERT(diff_norm > 0, "Watermark addition failed (no change)");
        std::cout << "Watermark added (Difference L2: " << diff_norm << ")" << std::endl;

        std::cout << "Removing watermark..." << std::endl;
        engine.remove_watermark(processed);

        // Check error
        cv::Mat diff;
        cv::absdiff(original, processed, diff);
        
        // Find max error
        double minVal, maxVal;
        cv::minMaxLoc(diff, &minVal, &maxVal);
        
        std::cout << "Restoration Max Absolute Error: " << maxVal << std::endl;

        // We expect the error to be small (<= 2 levels due to quantization)
        // With current noisy alpha map, it might be exactly 1 or 2.
        ASSERT(maxVal <= 2.0, "Restoration error too high");

        // Count pixels that are NOT perfectly restored
        int diff_pixels = cv::countNonZero(diff.reshape(1));
        std::cout << "Pixels with error: " << diff_pixels << std::endl;

        std::cout << "PASS: Regression test completed." << std::endl;
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "EXCEPTION: " << e.what() << std::endl;
        return 1;
    }
}
