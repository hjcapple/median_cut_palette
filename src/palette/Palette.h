#ifndef __PALETTE_PALETTE_H__
#define __PALETTE_PALETTE_H__

#include <cstdint>
#include <cstddef>
#include <functional>

namespace palette {

    typedef uint32_t RGBA;

    struct Cube final {
    public:
        RGBA getAverageRGBA() const;

    private:
        Cube(const int *hist, uint16_t *histPtr) : _hist(hist), _histPtr(histPtr) {
        }

        void shrink(uint16_t lower, uint16_t upper, uint16_t level);
        friend class Palette;

        static int findCubeToSplite(const Cube *cubes, size_t numCubes);
        void spliteCubes(Cube &cubeA, Cube &cubeB);

    private:
        const int *_hist;
        uint16_t *_histPtr;

        uint16_t _lower;
        uint16_t _upper;
        int _count;

        uint8_t _rmin, _rmax;
        uint8_t _gmin, _gmax;
        uint8_t _bmin, _bmax;
        int _volume;
        uint16_t _level;
    };

    class Palette final {
    public:
        Palette(const RGBA *colors, size_t colorSize);
        ~Palette();

        void medianCut(size_t maxcubes, const std::function<void(const Cube &)> &callback);

        Palette(const Palette &) = delete;
        Palette &operator=(const Palette &) = delete;

    private:
        static void spliteCubes(Cube *cubes, size_t &numCubes, size_t maxCubes);

    private:
        const RGBA *_colors;
        const size_t _colorSize;
        enum {
            kHistSize = 32768 // (1 << 15)
        };
        int *_hist;
        uint16_t *_histPtr;
    };
} // namespace palette

#endif
