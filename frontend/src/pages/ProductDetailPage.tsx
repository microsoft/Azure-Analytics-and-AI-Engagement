import React, { useState } from 'react';
import { useParams, Navigate, useNavigate } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';
import { Star, ShoppingCart, Heart, Share2, Truck, Shield, RotateCcw, ArrowLeft } from 'lucide-react';
import { RootState } from '../store/store';
import { addToCart } from '../store/cartSlice';

const ProductDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [selectedImage, setSelectedImage] = useState(0);
  const [quantity, setQuantity] = useState(1);

  const product = useSelector((state: RootState) =>
    state.products.products.find(p => p.id === id)
  );

  if (!product) {
    return <Navigate to="/products" replace />;
  }

  const handleAddToCart = () => {
    for (let i = 0; i < quantity; i++) {
      dispatch(addToCart(product));
    }
  };

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        className={`h-5 w-5 ${
          i < Math.floor(rating) ? 'text-yellow-400 fill-current' : 'text-gray-300'
        }`}
      />
    ));
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Product Images */}
          <div className="space-y-4 relative">
            {/* Back Button */}
            <button
              onClick={() => navigate(-1)}
              className="absolute top-7 left-4 z-10 bg-white/80 hover:bg-white text-gray-700 hover:text-blue-600 rounded-full p-2 shadow transition-colors flex items-center justify-center"
              aria-label="Back"
              style={{ backdropFilter: 'blur(4px)' }}
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <div className="aspect-square bg-white rounded-lg overflow-hidden">
              <img
                src={product.images[selectedImage]}
                alt={product.name}
                className="w-full h-full object-cover"
              />
            </div>
            {product.images.length > 1 && (
              <div className="flex space-x-2">
                {product.images.map((image, index) => (
                  <button
                    key={index}
                    onClick={() => setSelectedImage(index)}
                    className={`w-20 h-20 rounded-lg overflow-hidden border-2 transition-colors ${
                      selectedImage === index ? 'border-blue-500' : 'border-gray-200'
                    }`}
                  >
                    <img src={image} alt={`${product.name} ${index + 1}`} className="w-full h-full object-cover" />
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Product Details */}
          <div className="space-y-6">
            <div>
              <span className="text-blue-600 font-medium text-sm">{product.category}</span>
              <h1 className="text-3xl font-bold text-gray-900 mt-1">{product.name}</h1>
            </div>

            <div className="flex items-center space-x-4">
              <div className="flex items-center">
                {renderStars(product.rating)}
                <span className="ml-2 text-sm text-gray-600">
                  {product.rating} ({product.reviews} reviews)
                </span>
              </div>
            </div>

            <div className="flex items-center space-x-4">
              <span className="text-3xl font-bold text-gray-900">
                ${product.price.toFixed(2)}
              </span>
              {product.originalPrice && (
                <span className="text-xl text-gray-500 line-through">
                  ${product.originalPrice.toFixed(2)}
                </span>
              )}
              {product.originalPrice && (
                <span className="bg-red-100 text-red-800 px-2 py-1 rounded-full text-sm font-semibold">
                  Save ${(product.originalPrice - product.price).toFixed(2)}
                </span>
              )}
            </div>

            <div className={`px-4 py-2 rounded-lg inline-block ${
              product.inStock ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
            }`}>
              {product.inStock ? 'In Stock' : 'Out of Stock'}
            </div>

            <p className="text-gray-700 leading-relaxed">{product.description}</p>

            {/* Quantity and Add to Cart */}
            <div className="flex items-center space-x-4">
              <div className="flex items-center border border-gray-300 rounded-lg">
                <button
                  onClick={() => setQuantity(Math.max(1, quantity - 1))}
                  className="px-3 py-2 hover:bg-gray-100 transition-colors"
                >
                  -
                </button>
                <span className="px-4 py-2 border-x border-gray-300">{quantity}</span>
                <button
                  onClick={() => setQuantity(quantity + 1)}
                  className="px-3 py-2 hover:bg-gray-100 transition-colors"
                >
                  +
                </button>
              </div>

              <button
                onClick={handleAddToCart}
                disabled={!product.inStock}
                className={`flex-1 flex items-center justify-center px-6 py-3 rounded-lg font-semibold transition-colors ${
                  product.inStock
                    ? 'bg-blue-600 hover:bg-blue-700 text-white'
                    : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                }`}
              >
                <ShoppingCart className="mr-2 h-5 w-5" />
                Add to Cart
              </button>
            </div>

            {/* Action Buttons */}
            <div className="flex space-x-4">
              <button className="flex items-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
                <Heart className="mr-2 h-4 w-4" />
                Add to Wishlist
              </button>
              <button className="flex items-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
                <Share2 className="mr-2 h-4 w-4" />
                Share
              </button>
            </div>

            {/* Features */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-6 border-t">
              <div className="flex items-center space-x-2">
                <Truck className="h-5 w-5 text-blue-600" />
                <span className="text-sm text-gray-600">Free Shipping</span>
              </div>
              <div className="flex items-center space-x-2">
                <Shield className="h-5 w-5 text-green-600" />
                <span className="text-sm text-gray-600">2 Year Warranty</span>
              </div>
              <div className="flex items-center space-x-2">
                <RotateCcw className="h-5 w-5 text-orange-600" />
                <span className="text-sm text-gray-600">30 Day Return</span>
              </div>
            </div>
          </div>
        </div>

        {/* Specifications */}
        <div className="mt-16">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Specifications</h2>
          <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
            <div className="divide-y divide-gray-200">
              {Object.entries(product.specifications).map(([key, value]) => (
                <div key={key} className="px-6 py-4 flex justify-between">
                  <span className="font-medium text-gray-900">{key}</span>
                  <span className="text-gray-600">{value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductDetailPage;