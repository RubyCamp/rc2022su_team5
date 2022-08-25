# Mittsuの3D形状オブジェクト（Mesh）を生成するためのファクトリークラス
class MeshFactory
	# Mesh生成用クラスメソッド
	def self.generate(attr = {})
		raise "geom_typeキー(値: symbol)は必須です。" unless attr.has_key?(:geom_type)
		factory = self.new(attr)
		factory.build_mesh
	end

	def self.get_texture(texture_path)
		@@texture_cache ||= {}
		return @@texture_cache[texture_path] if @@texture_cache.has_key?(texture_path)

		@@texture_cache[texture_path] = Mittsu::ImageUtils.load_texture(texture_path)
	end

	# 地球のメッシュを生成して返す
	def self.get_earth
		attr = {
			geom_type: :sphere,
			segment_w: 16,
			segment_h: 16,
			mat_type: :phong,
			texture_map: get_texture("textures/Pancake.png"),
			normal_map: get_texture("textures/earth_normal.png")
		}
		generate(attr)
	end


	# コンストラクタ
	def initialize(attr)
		@geom_type = attr[:geom_type]
		@mat_type = attr[:mat_type]
		@attr = attr
	end

	# メッシュ生成
	def build_mesh
		if @geom_type == :frying_pan
			build_frying_pan
		else
			Mittsu::Mesh.new(build_geometry, build_material)
		end
	end

	private

	def build_frying_pan
		#geom_body = Mittsu::BoxGeometry.new(1, 1, 1, 4, 4, 4)
		geom_body = Mittsu::SphereGeometry.new(1, 16, 16, 0.0, Math::PI * 2, Math::PI, Math::PI / 2)
		mat_body = Mittsu::MeshLambertMaterial.new(color: 0x666666)
		mesh_body = Mittsu::Mesh.new(geom_body, mat_body)
		geom_lenz = Mittsu::CylinderGeometry.new(0.1, 0.15, 1)
		mat_lenz = Mittsu::MeshLambertMaterial.new(color:0x666666)
		mesh_lenz = Mittsu::Mesh.new(geom_lenz, mat_lenz)
		mesh_body.add(mesh_lenz)
		mesh_lenz.position.x = -1.45          # -X方向に1.5移動（高さを1.5にしているため）
		mesh_lenz.position.y = -0.25
		mesh_lenz.rotation.z = Math::PI / 2
		mesh_body
	end

	# ジオメトリ生成
	def build_geometry
		geom = nil
		case @geom_type
		# 立方体ジオメトリ生成
		when :box
			scale_x = @attr[:scale_x] || 1.0
			scale_y = @attr[:scale_y] || 1.0
			scale_z = @attr[:scale_z] || 1.0
			segment_x = @attr[:segment_x] || 1
			segment_y = @attr[:segment_y] || 1
			segment_z = @attr[:segment_z] || 1
			geom = Mittsu::BoxGeometry.new(
				scale_x, scale_y, scale_z,
				segment_x, segment_y, segment_z)

		# 球ジオメトリ生成
		when :sphere
			radius = @attr[:radius] || 5.0
			segment_w = @attr[:segment_w] || 12
			segment_h = @attr[:segment_h] || 12
			phi_start = @attr[:phi_start] || 0.0
			phi_length = @attr[:phi_length] || ::Math::PI * 2.0
			theta_start = @attr[:theta_start] || 0.0
			theta_length = @attr[:theta_length] || ::Math::PI
			geom = Mittsu::SphereGeometry.new(
				radius, segment_w, segment_h,
				phi_start, phi_length,
				theta_start, theta_length)

		# 円柱ジオメトリ生成
		when :cylinder
			radius_top = @attr[:radius_top] || 1.0
			radius_bottom = @attr[:radius_bottom] || 1.0
			height = @attr[:height] || 0.3
			radial_segments = @attr[:radial_segments] || 12
			height_segments = @attr[:height_segments] || 1
			open_ended = @attr[:open_ended] || false
			theta_start = @attr[:theta_start] || 0.0
			theta_length = @attr[:theta_length] || ::Math::PI * 2.0
			geom = Mittsu::CylinderGeometry.new(
				radius_top, radius_bottom, height,
		  		radial_segments, height_segments, open_ended,
		  		theta_start, theta_length)	
				# 板ジオメトリ生成
		when :plane
			scale_x = @attr[:scale_x] || 1.0
			scale_y = @attr[:scale_y] || 1.0
			segment_x = @attr[:segment_x] || 1
			segment_y = @attr[:segment_y] || 1
			geom = Mittsu::PlaneGeometry.new(
				scale_x, scale_y,
				segment_x, segment_y)

		# NOTE: 以下、必要に応じて拡張する
		end

		raise "不正なtypeが指定されました。" unless geom
		geom
	end

	# マテリアル生成
	def build_material
		mat = nil
		color = @attr[:color] || 0xff0000
		texture_map = Mittsu::ImageUtils.load_texture("./earth.png")
		normal_map = Mittsu::ImageUtils.load_texture("./earth.png")

		texture_map = @attr[:texture_map] || nil
		normal_map = @attr[:normal_map] || nil
		wireframe = @attr[:wireframe] ? true : false
		attr = {wireframe: wireframe}
		case @mat_type
		when :lambert
			attr[:map] = texture_map if texture_map
			attr[:color] = color unless attr.has_key?(:map)
			mat = Mittsu::MeshLambertMaterial.new(attr)

		when :phong
			attr[:map] = texture_map if texture_map
			attr[:normal_map] = normal_map if normal_map
			attr[:color] = color if !attr.has_key?(:map) && !attr.has_key?(:normal_map)
			mat = Mittsu::MeshPhongMaterial.new(attr)

		else # デフォルトはBasicマテリアルを選択する
			attr[:color] = color
			mat = Mittsu::MeshBasicMaterial.new(attr)
		end
		mat
	end
end